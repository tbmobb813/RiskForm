import 'package:cloud_firestore/cloud_firestore.dart';

class StrategyHealthSnapshot {
  final String strategyId;

  // -----------------------------
  // Performance
  // -----------------------------
  final List<double> pnlTrend; // normalized or raw PnL values
  final List<Map<String, dynamic>> cycleSummaries;

  // -----------------------------
  // Discipline
  // -----------------------------
  final List<double> disciplineTrend;

  // -----------------------------
  // Regime
  // -----------------------------
  final Map<String, dynamic> regimePerformance;
  // e.g. { "uptrend": {...}, "downtrend": {...} }

  // -----------------------------
  // Flags (optional)
  // -----------------------------
  final List<String> flags;

  // -----------------------------
  // Metadata
  // -----------------------------
  final DateTime updatedAt;

  const StrategyHealthSnapshot({
    required this.strategyId,
    required this.pnlTrend,
    required this.cycleSummaries,
    required this.disciplineTrend,
    required this.regimePerformance,
    required this.flags,
    required this.updatedAt,
  });

  // ------------------------------------------------------------
  // Firestore → Model
  // ------------------------------------------------------------
  factory StrategyHealthSnapshot.fromFirestore(
    DocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    return StrategyHealthSnapshot(
      strategyId: data['strategyId'] as String,
      pnlTrend: List<double>.from(
        (data['pnlTrend'] ?? []).map((e) => (e as num).toDouble()),
      ),
      cycleSummaries: List<Map<String, dynamic>>.from(
        data['cycleSummaries'] ?? [],
      ),
      disciplineTrend: List<double>.from(
        (data['disciplineTrend'] ?? []).map((e) => (e as num).toDouble()),
      ),
      regimePerformance: Map<String, dynamic>.from(
        data['regimePerformance'] ?? {},
      ),
      flags: List<String>.from(data['flags'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // ------------------------------------------------------------
  // Model → Firestore
  // ------------------------------------------------------------
  Map<String, dynamic> toFirestore() {
    return {
      'strategyId': strategyId,
      'pnlTrend': pnlTrend,
      'cycleSummaries': cycleSummaries,
      'disciplineTrend': disciplineTrend,
      'regimePerformance': regimePerformance,
      'flags': flags,
      'updatedAt': updatedAt,
    };
  }

  // ------------------------------------------------------------
  // Immutable Copy
  // ------------------------------------------------------------
  StrategyHealthSnapshot copyWith({
    List<double>? pnlTrend,
    List<Map<String, dynamic>>? cycleSummaries,
    List<double>? disciplineTrend,
    Map<String, dynamic>? regimePerformance,
    List<String>? flags,
    DateTime? updatedAt,
  }) {
    return StrategyHealthSnapshot(
      strategyId: strategyId,
      pnlTrend: pnlTrend ?? this.pnlTrend,
      cycleSummaries: cycleSummaries ?? this.cycleSummaries,
      disciplineTrend: disciplineTrend ?? this.disciplineTrend,
      regimePerformance: regimePerformance ?? this.regimePerformance,
      flags: flags ?? this.flags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
