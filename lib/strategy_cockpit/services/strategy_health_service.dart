import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

import '../../models/strategy_health_snapshot.dart';
import '../models/strategy_cycle.dart';

class StrategyHealthService {
  final FirebaseFirestore? _firestore;

  StrategyHealthService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // Collection reference
  // ------------------------------------------------------------
  CollectionReference get _health => _db.collection('strategyHealth');

  // ------------------------------------------------------------
  // Watch health snapshot for a strategy
  // ------------------------------------------------------------
  Stream<StrategyHealthSnapshot?> watchHealth(String strategyId) {
    return _health.doc(strategyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StrategyHealthSnapshot.fromFirestore(doc);
    });
  }

  // ------------------------------------------------------------
  // Fetch latest health snapshot once
  // ------------------------------------------------------------
  Future<StrategyHealthSnapshot?> fetchLatestHealth(
      String strategyId) async {
    final doc = await _health.doc(strategyId).get();
    if (!doc.exists) return null;
    return StrategyHealthSnapshot.fromFirestore(doc);
  }

  // ------------------------------------------------------------
  // Upsert health snapshot (for Cloud worker / batch jobs)
  // ------------------------------------------------------------
  Future<void> saveHealthSnapshot(
    StrategyHealthSnapshot snapshot,
  ) async {
    await _health.doc(snapshot.strategyId).set(
          snapshot.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // ------------------------------------------------------------
  // Partial update (e.g., only flags or regimePerformance)
  // ------------------------------------------------------------
  Future<void> updateHealthFields({
    required String strategyId,
    Map<String, dynamic>? fields,
  }) async {
    if (fields == null || fields.isEmpty) return;

    fields['updatedAt'] = FieldValue.serverTimestamp();

    await _health.doc(strategyId).update(fields);
  }

  // ------------------------------------------------------------
  // Transaction-aware: mark health as dirty so a worker can recompute
  // ------------------------------------------------------------
  Future<void> markHealthDirtyInTx({
    required Transaction tx,
    required String strategyId,
  }) async {
    final ref = _health.doc(strategyId);
    tx.set(ref, {
      'strategyId': strategyId,
      'dirty': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ------------------------------------------------------------
  // Recompute health by aggregating all cycles for a strategy
  // ------------------------------------------------------------
  Future<void> recomputeHealth(String strategyId) async {
    // 1) Load all cycles for the strategy ordered by start time
    final query = await _db
      .collection('strategyCycles')
        .where('strategyId', isEqualTo: strategyId)
        .orderBy('startedAt')
        .get();

    final cycles = query.docs
        .map((d) => StrategyCycle.fromFirestore(d))
        .toList();

    // 2) Compute snapshot
    final snapshot = _computeSnapshot(strategyId, cycles);

    // 3) Persist snapshot (replace)
    await _health.doc(strategyId).set(
      snapshot.toFirestore(),
      SetOptions(merge: false),
    );
  }

  // ------------------------------------------------------------
  // Core aggregation logic
  // ------------------------------------------------------------
  StrategyHealthSnapshot _computeSnapshot(
    String strategyId,
    List<StrategyCycle> cycles,
  ) {
    if (cycles.isEmpty) return StrategyHealthSnapshot.empty(strategyId);

    // 1. Existing aggregates
    final pnlTrend = cycles.map((c) => c.realizedPnl + c.unrealizedPnl).toList();

    final disciplineTrend = cycles.map((c) => c.disciplineScore).toList();

    final Map<String, _RegimeStats> regimeStats = {};
    for (final c in cycles) {
      final regime = c.dominantRegime ?? 'unknown';
      regimeStats.putIfAbsent(regime, () => _RegimeStats());
      final stats = regimeStats[regime]!;
      stats.count++;
      stats.totalPnl += c.realizedPnl;
      stats.totalDiscipline += c.disciplineScore;
      if (c.realizedPnl > 0) stats.wins++;
    }

    final regimePerformance = <String, Map<String, dynamic>>{};
    regimeStats.forEach((regime, stats) {
      final winRate = stats.count == 0 ? 0.0 : stats.wins / stats.count;
      final avgDiscipline = stats.count == 0 ? 0.0 : stats.totalDiscipline / stats.count;
      regimePerformance[regime] = {
        'pnl': stats.totalPnl,
        'winRate': winRate,
        'avgDiscipline': avgDiscipline,
      };
    });

    final weaknesses = <String>[];
    if (disciplineTrend.isNotEmpty && disciplineTrend.last < 60) {
      weaknesses.add('discipline_slipping');
    }
    if (pnlTrend.length >= 3) {
      final last3 = pnlTrend.sublist(pnlTrend.length - 3);
      if (last3.every((p) => p < 0)) weaknesses.add('recent_losses');
    }

    final cycleSummaries = cycles.map((c) {
      return {
        'cycleId': c.id,
        'pnl': c.realizedPnl + c.unrealizedPnl,
        'disciplineScore': c.disciplineScore,
        'regime': c.dominantRegime,
        'startedAt': c.startedAt,
        'closedAt': c.closedAt,
      };
    }).toList();

    final lastCycle = cycles.last;
    final currentRegime = lastCycle.dominantRegime;
    final currentRegimeHint = switch (currentRegime) {
      'uptrend' => 'Strategy performs best selling premium in strength.',
      'downtrend' => 'Strategy may require defensive adjustments.',
      'sideways' => 'Neutral conditions favor income strategies.',
      _ => 'No regime signal available.',
    };

    // 2. Health score components
    final performanceScore = _computePerformanceScore(pnlTrend);
    final disciplineScore = _computeDisciplineScore(disciplineTrend);
    final regimeScore = _computeRegimeScore(regimePerformance, currentRegime);
    final consistencyScore = _computeConsistencyScore(pnlTrend);

    final healthScore =
        0.35 * performanceScore +
        0.35 * disciplineScore +
        0.20 * regimeScore +
        0.10 * consistencyScore;

    final clampedHealth = healthScore.clamp(0, 100).toDouble();

    final healthLabel = clampedHealth >= 80
        ? 'Stable'
        : clampedHealth >= 60
            ? 'Fragile'
            : 'At Risk';

    // If you want to persist a trend, you'd load previous snapshot here.
    final healthTrend = <double>[clampedHealth];

    return StrategyHealthSnapshot(
      strategyId: strategyId,
      pnlTrend: pnlTrend,
      disciplineTrend: disciplineTrend,
      regimePerformance: regimePerformance,
      cycleSummaries: cycleSummaries,
      regimeWeaknesses: weaknesses,
      currentRegime: currentRegime,
      currentRegimeHint: currentRegimeHint,
      updatedAt: DateTime.now(),
      healthScore: clampedHealth,
      healthLabel: healthLabel,
      healthTrend: healthTrend,
    );
  }

  // ------------------------------------------------------------
  // Health score helper methods
  // ------------------------------------------------------------
  double _computePerformanceScore(List<double> pnlTrend) {
    if (pnlTrend.isEmpty) return 50;

    final window = pnlTrend.length >= 5
        ? pnlTrend.sublist(pnlTrend.length - 5)
        : List<double>.from(pnlTrend);

    final avg = window.reduce((a, b) => a + b) / window.length;

    double equity = 0;
    double peak = 0;
    double maxDrawdown = 0;
    for (final p in window) {
      equity += p;
      if (equity > peak) peak = equity;
      final dd = peak - equity;
      if (dd > maxDrawdown) maxDrawdown = dd;
    }

    final base = (avg / (avg.abs() + 1)) * 50 + 50; // map to ~0–100
    final ddPenalty = (maxDrawdown > 0)
        ? (maxDrawdown / (maxDrawdown + 1)) * 30
        : 0;

    final score = base - ddPenalty;
    return score.clamp(0, 100).toDouble();
  }

  double _computeDisciplineScore(List<double> disciplineTrend) {
    if (disciplineTrend.isEmpty) return 50;

    final window = disciplineTrend.length >= 5
        ? disciplineTrend.sublist(disciplineTrend.length - 5)
        : List<double>.from(disciplineTrend);

    final current = window.last;
    final first = window.first;
    final delta = current - first;

    double score = current;

    if (delta < 0) {
      final penalty = (-delta / 20).clamp(0, 15); // up to -15
      score -= penalty;
    } else if (delta > 0) {
      final bonus = (delta / 20).clamp(0, 10); // up to +10
      score += bonus;
    }

    return score.clamp(0, 100).toDouble();
  }

  double _computeRegimeScore(
    Map<String, Map<String, dynamic>> regimePerformance,
    String? currentRegime,
  ) {
    if (regimePerformance.isEmpty) return 50;

    Map<String, dynamic>? rp;
    if (currentRegime != null && regimePerformance.containsKey(currentRegime)) {
      rp = regimePerformance[currentRegime];
    } else {
      double totalPnl = 0;
      double totalWinRate = 0;
      double totalDisc = 0;
      int count = 0;
      regimePerformance.forEach((_, v) {
        totalPnl += (v['pnl'] ?? 0) is num ? (v['pnl'] as num).toDouble() : 0.0;
        totalWinRate += (v['winRate'] ?? 0) is num ? (v['winRate'] as num).toDouble() : 0.0;
        totalDisc += (v['avgDiscipline'] ?? 0) is num ? (v['avgDiscipline'] as num).toDouble() : 0.0;
        count++;
      });
      if (count == 0) return 50;
      rp = {
        'pnl': totalPnl / count,
        'winRate': totalWinRate / count,
        'avgDiscipline': totalDisc / count,
      };
    }

    final pnl = (rp?['pnl'] ?? 0) is num ? (rp?['pnl'] as num).toDouble() : 0.0;
    final winRate = (rp?['winRate'] ?? 0) is num ? (rp?['winRate'] as num).toDouble() : 0.0;
    final avgDisc = (rp?['avgDiscipline'] ?? 0) is num ? (rp?['avgDiscipline'] as num).toDouble() : 0.0;

    final pnlComponent = (pnl / (pnl.abs() + 1)) * 40 + 50; // ~10–90
    final winComponent = (winRate * 100).clamp(0, 100) * 0.4;
    final discComponent = avgDisc * 0.2;

    final score = (pnlComponent * 0.4) + winComponent + discComponent;
    return score.clamp(0, 100).toDouble();
  }

  double _computeConsistencyScore(List<double> pnlTrend) {
    if (pnlTrend.length < 2) return 50;

    final window = pnlTrend.length >= 5
        ? pnlTrend.sublist(pnlTrend.length - 5)
        : List<double>.from(pnlTrend);

    final mean = window.reduce((a, b) => a + b) / window.length;
    final variance = window.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / window.length;
    final stdDev = math.sqrt(variance);

    // Normalize stdDev into 0–100, then invert
    final normalized = (stdDev / (stdDev + 1)) * 100;
    final score = 100 - normalized;

    return score.clamp(0, 100).toDouble();
  }
}

class _RegimeStats {
  int count = 0;
  int wins = 0;
  double totalPnl = 0.0;
  double totalDiscipline = 0.0;
}
