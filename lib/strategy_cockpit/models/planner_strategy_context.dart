import 'package:cloud_firestore/cloud_firestore.dart';

/// Context passed from Strategy Cockpit → Planner.
/// Gives the Planner everything it needs to enforce constraints,
/// surface warnings, and provide strategy-aware hints.
class PlannerStrategyContext {
  final String strategyId;
  final String strategyName;
  final String state; // active | paused | retired | experimental

  // Tags help Planner pre-filter playbooks or show relevant UI.
  final List<String> tags;

  // Constraint summary (human-readable)
  final String? constraintsSummary;

  // Raw constraints map (machine-readable)
  final Map<String, dynamic> constraints;

  // Regime context (e.g., "uptrend", "downtrend", "sideways")
  final String? currentRegime;

  // Discipline flags (e.g., ["risk discipline slipping", "timing violations"])
  final List<String> disciplineFlags;

  // Last updated timestamp (for Planner to know freshness)
  final DateTime updatedAt;

  const PlannerStrategyContext({
    required this.strategyId,
    required this.strategyName,
    required this.state,
    required this.tags,
    required this.constraintsSummary,
    required this.constraints,
    required this.currentRegime,
    required this.disciplineFlags,
    required this.updatedAt,
  });

  /// ------------------------------------------------------------
  /// Firestore → Model
  /// ------------------------------------------------------------
  factory PlannerStrategyContext.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PlannerStrategyContext(
      strategyId: data['strategyId'] as String,
      strategyName: data['strategyName'] as String,
      state: data['state'] as String,
      tags: List<String>.from(data['tags'] ?? []),
      constraintsSummary: data['constraintsSummary'],
      constraints: Map<String, dynamic>.from(data['constraints'] ?? {}),
      currentRegime: data['currentRegime'],
      disciplineFlags: List<String>.from(data['disciplineFlags'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// ------------------------------------------------------------
  /// Model → Firestore
  /// ------------------------------------------------------------
  Map<String, dynamic> toFirestore() {
    return {
      'strategyId': strategyId,
      'strategyName': strategyName,
      'state': state,
      'tags': tags,
      'constraintsSummary': constraintsSummary,
      'constraints': constraints,
      'currentRegime': currentRegime,
      'disciplineFlags': disciplineFlags,
      'updatedAt': updatedAt,
    };
  }

  /// ------------------------------------------------------------
  /// Immutable copy
  /// ------------------------------------------------------------
  PlannerStrategyContext copyWith({
    String? strategyId,
    String? strategyName,
    String? state,
    List<String>? tags,
    String? constraintsSummary,
    Map<String, dynamic>? constraints,
    String? currentRegime,
    List<String>? disciplineFlags,
    DateTime? updatedAt,
  }) {
    return PlannerStrategyContext(
      strategyId: strategyId ?? this.strategyId,
      strategyName: strategyName ?? this.strategyName,
      state: state ?? this.state,
      tags: tags ?? this.tags,
      constraintsSummary: constraintsSummary ?? this.constraintsSummary,
      constraints: constraints ?? this.constraints,
      currentRegime: currentRegime ?? this.currentRegime,
      disciplineFlags: disciplineFlags ?? this.disciplineFlags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
