import '../../strategy_cockpit/models/strategy_health_snapshot.dart';

class StrategyDisciplineAnalyzer {
  // ------------------------------------------------------------
  // Discipline Trend (already in snapshot)
  // ------------------------------------------------------------
  static List<double> getTrend(StrategyHealthSnapshot snapshot) {
    return snapshot.disciplineTrend;
  }

  // ------------------------------------------------------------
  // Violations Breakdown
  // Returns: { 'adherence': x, 'timing': y, 'risk': z }
  // ------------------------------------------------------------
  static Map<String, int> computeViolationBreakdown(
      StrategyHealthSnapshot snapshot) {
    final cycles = snapshot.cycleSummaries;
    if (cycles.isEmpty) {
      return {'adherence': 0, 'timing': 0, 'risk': 0};
    }

    int adherence = 0;
    int timing = 0;
    int risk = 0;

    for (final cycle in cycles) {
      final breakdown = cycle['disciplineBreakdown'] ?? {};
      adherence += (breakdown['adherence'] ?? 0) < 30 ? 1 : 0;
      timing += (breakdown['timing'] ?? 0) < 20 ? 1 : 0;
      risk += (breakdown['risk'] ?? 0) < 20 ? 1 : 0;
    }

    return {
      'adherence': adherence,
      'timing': timing,
      'risk': risk,
    };
  }

  // ------------------------------------------------------------
  // Clean Cycle Streak
  // Clean cycle = disciplineScore >= 80
  // ------------------------------------------------------------
  static int computeCleanCycleStreak(StrategyHealthSnapshot snapshot) {
    int streak = 0;

    for (final cycle in snapshot.cycleSummaries) {
      final score = (cycle['disciplineScore'] ?? 0).toDouble();
      if (score >= 80) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ------------------------------------------------------------
  // Adherence Streak
  // adherence >= 30/40
  // ------------------------------------------------------------
  static int computeAdherenceStreak(StrategyHealthSnapshot snapshot) {
    int streak = 0;

    for (final cycle in snapshot.cycleSummaries) {
      final breakdown = cycle['disciplineBreakdown'] ?? {};
      final adherence = (breakdown['adherence'] ?? 0).toDouble();

      if (adherence >= 30) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ------------------------------------------------------------
  // Risk Discipline Streak
  // risk >= 20/30
  // ------------------------------------------------------------
  static int computeRiskStreak(StrategyHealthSnapshot snapshot) {
    int streak = 0;

    for (final cycle in snapshot.cycleSummaries) {
      final breakdown = cycle['disciplineBreakdown'] ?? {};
      final risk = (breakdown['risk'] ?? 0).toDouble();

      if (risk >= 20) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ------------------------------------------------------------
  // Recent Discipline Events (last 5 cycles)
  // ------------------------------------------------------------
  static List<Map<String, dynamic>> recentDisciplineEvents(
      StrategyHealthSnapshot snapshot) {
    return snapshot.cycleSummaries.take(5).toList();
  }

  // ------------------------------------------------------------
  // Most Common Violation Type
  // Returns: "adherence" | "timing" | "risk" | "none"
  // ------------------------------------------------------------
  static String computeMostCommonViolation(
      StrategyHealthSnapshot snapshot) {
    final breakdown = computeViolationBreakdown(snapshot);

    if (breakdown.values.every((v) => v == 0)) {
      return 'none';
    }

    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  // ------------------------------------------------------------
  // Cycle-level adapter (static) for Execution → Cycle wiring
  // ------------------------------------------------------------
  static CycleDisciplineResult computeCycleDiscipline({
    required List<Map<String, dynamic>> executions,
    required List<String> disciplineFlags,
    required Map<String, dynamic> constraints,
  }) {
    // Simple heuristic: start at 100, subtract per flag and small penalty per violation
    double score = 100;
    score -= (disciplineFlags.length * 5);

    final Map<String, int> violations = {};
    // Placeholder: detect simple timing/risk issues from executions
    for (final e in executions) {
      final type = (e['type'] ?? '').toString().toLowerCase();
      if (type.contains('late') || type.contains('slippage')) {
        violations['timing'] = (violations['timing'] ?? 0) + 1;
        score -= 2;
      }
    }

    if (score < 0) score = 0;

    return CycleDisciplineResult(
      score: score,
      violations: violations,
      streakImpact: 0.0,
    );
  }
}
class CycleDisciplineResult {
  final double score;
  final Map<String, dynamic> violations;
  final double streakImpact;

  CycleDisciplineResult({
    required this.score,
    required this.violations,
    required this.streakImpact,
  });
}

extension StrategyDisciplineAdapter on StrategyDisciplineAnalyzer {
  static CycleDisciplineResult computeCycleDiscipline({
    required List<Map<String, dynamic>> executions,
    required List<String> disciplineFlags,
    required Map<String, dynamic> constraints,
  }) {
    // Simple heuristic: start at 100, subtract per flag and small penalty per violation
    double score = 100;
    score -= (disciplineFlags.length * 5);

    final Map<String, int> violations = {};
    // Placeholder: detect simple timing/risk issues from executions
    for (final e in executions) {
      final type = (e['type'] ?? '').toString().toLowerCase();
      if (type.contains('late') || type.contains('slippage')) {
        violations['timing'] = (violations['timing'] ?? 0) + 1;
        score -= 2;
      }
    }

    if (score < 0) score = 0;

    return CycleDisciplineResult(
      score: score,
      violations: violations,
      streakImpact: 0.0,
    );
  }
}
