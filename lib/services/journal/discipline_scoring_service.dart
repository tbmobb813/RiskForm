import '../../models/journal/journal_entry.dart';
import '../../models/journal/discipline_score.dart';
import '../../models/analytics/market_regime.dart';

/// Scoring configuration constants.
/// These values define how discipline scores are calculated.
class ScoringConstants {
  ScoringConstants._();

  // --- Cycle Quality Normalization ---
  /// Expected average monthly return for "neutral" quality (0.5 score).
  /// A 5% monthly return is considered baseline performance.
  static const double expectedMonthlyReturn = 0.05;

  /// Range for normalizing cycle returns to 0-1 scale.
  /// Returns from -5% to +5% map to 0-1 quality score.
  static const double returnNormalizationRange = 0.10;

  // --- Regime Awareness Normalization ---
  /// Expected return offset for downtrend cycles.
  /// Downtrend cycles are expected to have lower/negative returns.
  static const double downtrendReturnOffset = 0.10;

  /// Range for normalizing downtrend returns to 0-1 scale.
  static const double downtrendNormalizationRange = 0.20;

  // --- Score Component Weights ---
  /// Weight for plan adherence in final score (35%).
  /// Measures how well the trader follows their planned strategy.
  static const double planAdherenceWeight = 0.35;

  /// Weight for cycle quality in final score (25%).
  /// Measures the average return quality of completed cycles.
  static const double cycleQualityWeight = 0.25;

  /// Weight for assignment behavior in final score (20%).
  /// Measures how well assignments are managed through to called-away.
  static const double assignmentBehaviorWeight = 0.20;

  /// Weight for regime awareness in final score (20%).
  /// Measures performance during difficult market conditions.
  static const double regimeAwarenessWeight = 0.20;

  // --- Score Scaling ---
  /// Multiplier to convert 0-1 score to 0-100 scale.
  static const double scoreMultiplier = 100.0;
}

class DisciplineScoringService {
  DisciplineScore compute(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return DisciplineScore(
        score: 0.0,
        planAdherence: 0.0,
        cycleQuality: 0.0,
        assignmentBehavior: 0.0,
        regimeAwareness: 0.0,
      );
    }

    final cycles = entries.where((e) => e.type == 'cycle').toList();
    final completedCycles = entries.where((e) => e.type == 'calledAway').length;

    final planAdherence = cycles.isEmpty
        ? 0.0
        : (completedCycles / cycles.length).clamp(0, 1).toDouble();

    final avgCycleReturn = cycles.isEmpty
        ? 0.0
        : cycles
                .map((e) => (e.data['cycleReturn'] is num) ? (e.data['cycleReturn'] as num).toDouble() : 0.0)
                .fold(0.0, (a, b) => a + b) /
            cycles.length;

    // Normalize cycle return: -5% to +5% maps to 0-1
    final cycleQuality = ((avgCycleReturn + ScoringConstants.expectedMonthlyReturn) /
            ScoringConstants.returnNormalizationRange)
        .clamp(0, 1)
        .toDouble();

    final assignments = entries.where((e) => e.type == 'assignment').length;
    final calledAway = entries.where((e) => e.type == 'calledAway').length;

    final assignmentBehavior = assignments == 0 ? 1.0 : (calledAway / assignments).clamp(0, 1).toDouble();

    final downCycles =
        cycles.where((e) => e.data['dominantRegime'] == MarketRegime.downtrend.toString()).toList();

    double regimeAwareness = 1.0;
    if (downCycles.isNotEmpty) {
      final avgDownReturn = downCycles
              .map((e) => (e.data['cycleReturn'] is num) ? (e.data['cycleReturn'] as num).toDouble() : 0.0)
              .fold(0.0, (a, b) => a + b) /
          downCycles.length;

      // Normalize downtrend return: -10% to +10% maps to 0-1
      regimeAwareness = ((avgDownReturn + ScoringConstants.downtrendReturnOffset) /
              ScoringConstants.downtrendNormalizationRange)
          .clamp(0, 1)
          .toDouble();
    }

    // Weighted average of all components
    final score = (planAdherence * ScoringConstants.planAdherenceWeight +
            cycleQuality * ScoringConstants.cycleQualityWeight +
            assignmentBehavior * ScoringConstants.assignmentBehaviorWeight +
            regimeAwareness * ScoringConstants.regimeAwarenessWeight) *
        ScoringConstants.scoreMultiplier;

    return DisciplineScore(
      score: score,
      planAdherence: planAdherence,
      cycleQuality: cycleQuality,
      assignmentBehavior: assignmentBehavior,
      regimeAwareness: regimeAwareness,
    );
  }
}
