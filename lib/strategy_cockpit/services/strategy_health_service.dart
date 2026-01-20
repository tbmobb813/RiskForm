import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/strategy_health_snapshot.dart';
import '../models/strategy_cycle.dart';

class StrategyHealthService {
  final FirebaseFirestore _firestore;

  StrategyHealthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // Collection reference
  // ------------------------------------------------------------
  CollectionReference get _health =>
      _firestore.collection('strategyHealth');

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
    final query = await _firestore
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

    // 1) PnL Trend
    final pnlTrend = cycles.map((c) => c.realizedPnl + c.unrealizedPnl).toList();

    // 2) Discipline Trend
    final disciplineTrend = cycles.map((c) => c.disciplineScore).toList();

    // 3) Regime Performance Aggregation
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

    // 4) Weakness Flags
    final weaknesses = <String>[];
    if (disciplineTrend.isNotEmpty && disciplineTrend.last < 60) {
      weaknesses.add('discipline_slipping');
    }

    if (pnlTrend.length >= 3) {
      final last3 = pnlTrend.sublist(pnlTrend.length - 3);
      if (last3.every((p) => p < 0)) weaknesses.add('recent_losses');
    }

    // 5) Cycle Summaries
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

    // 6) Current Regime Hint
    final lastCycle = cycles.last;
    final currentRegime = lastCycle.dominantRegime;

    final currentRegimeHint = switch (currentRegime) {
      'uptrend' => 'Strategy performs best selling premium in strength.',
      'downtrend' => 'Strategy may require defensive adjustments.',
      'sideways' => 'Neutral conditions favor income strategies.',
      _ => 'No regime signal available.',
    };

    // 7) Build snapshot
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
    );
  }
}

class _RegimeStats {
  int count = 0;
  int wins = 0;
  double totalPnl = 0.0;
  double totalDiscipline = 0.0;
}
