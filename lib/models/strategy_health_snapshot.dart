import 'package:cloud_firestore/cloud_firestore.dart';

/// The authoritative, aggregated health state for a strategy.
/// Computed by StrategyHealthService.recomputeHealth().
class StrategyHealthSnapshot {
  final String strategyId;

  // Performance trend (cycle-level PnL)
  final List<double> pnlTrend;

  // Discipline trend (cycle-level discipline score)
  final List<double> disciplineTrend;

  // Regime performance breakdown
  final Map<String, Map<String, dynamic>> regimePerformance;

  // Cycle summaries for UI tables
  final List<Map<String, dynamic>> cycleSummaries;

  // Weakness flags (discipline slipping, recent losses, regime mismatch, etc.)
  final List<String> regimeWeaknesses;

  // Current regime + hint
  final String? currentRegime;
  final String? currentRegimeHint;

  // Last recompute timestamp
  final DateTime updatedAt;

  const StrategyHealthSnapshot({
    required this.strategyId,
    required this.pnlTrend,
    required this.disciplineTrend,
    required this.regimePerformance,
    required this.cycleSummaries,
    required this.regimeWeaknesses,
    required this.currentRegime,
    required this.currentRegimeHint,
    required this.updatedAt,
  });

  /// Empty snapshot (used when no cycles exist yet)
  factory StrategyHealthSnapshot.empty(String strategyId) {
    return StrategyHealthSnapshot(
      strategyId: strategyId,
      pnlTrend: const [],
      disciplineTrend: const [],
      regimePerformance: const {},
      cycleSummaries: const [],
      regimeWeaknesses: const [],
      currentRegime: null,
      currentRegimeHint: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Firestore → Model
  factory StrategyHealthSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StrategyHealthSnapshot(
      strategyId: data['strategyId'] as String,
      pnlTrend: List<double>.from(
        (data['pnlTrend'] ?? []).map((v) => (v as num).toDouble()),
      ),
      disciplineTrend: List<double>.from(
        (data['disciplineTrend'] ?? []).map((v) => (v as num).toDouble()),
      ),
      regimePerformance: Map<String, Map<String, dynamic>>.from(
        (data['regimePerformance'] ?? {}).map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
        ),
      ),
      cycleSummaries: List<Map<String, dynamic>>.from(
        (data['cycleSummaries'] ?? []).map((v) => Map<String, dynamic>.from(v)),
      ),
      regimeWeaknesses: List<String>.from(data['regimeWeaknesses'] ?? []),
      currentRegime: data['currentRegime'],
      currentRegimeHint: data['currentRegimeHint'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'strategyId': strategyId,
      'pnlTrend': pnlTrend,
      'disciplineTrend': disciplineTrend,
      'regimePerformance': regimePerformance,
      'cycleSummaries': cycleSummaries,
      'regimeWeaknesses': regimeWeaknesses,
      'currentRegime': currentRegime,
      'currentRegimeHint': currentRegimeHint,
      'updatedAt': updatedAt,
    };
  }

  /// Immutable copy
  StrategyHealthSnapshot copyWith({
    List<double>? pnlTrend,
    List<double>? disciplineTrend,
    Map<String, Map<String, dynamic>>? regimePerformance,
    List<Map<String, dynamic>>? cycleSummaries,
    List<String>? regimeWeaknesses,
    String? currentRegime,
    String? currentRegimeHint,
    DateTime? updatedAt,
  }) {
    return StrategyHealthSnapshot(
      strategyId: strategyId,
      pnlTrend: pnlTrend ?? this.pnlTrend,
      disciplineTrend: disciplineTrend ?? this.disciplineTrend,
      regimePerformance: regimePerformance ?? this.regimePerformance,
      cycleSummaries: cycleSummaries ?? this.cycleSummaries,
      regimeWeaknesses: regimeWeaknesses ?? this.regimeWeaknesses,
      currentRegime: currentRegime ?? this.currentRegime,
      currentRegimeHint: currentRegimeHint ?? this.currentRegimeHint,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
