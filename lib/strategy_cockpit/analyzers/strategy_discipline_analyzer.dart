class StrategyCycleDiscipline {
  final double score; // 0–100
  final Map<String, int> violations; // e.g. { adherence: 2, timing: 1, risk: 0 }
  final int streakImpact; // optional: net effect on streaks

  const StrategyCycleDiscipline({
    required this.score,
    required this.violations,
    required this.streakImpact,
  });
}

class StrategyDisciplineAnalyzer {
  /// executions: trade summaries
  /// disciplineFlags: flags from StrategyHealth / context (e.g. ["timing_slippage"]) 
  /// constraints: strategy constraints (maxRisk, maxPositions, etc.)
  static StrategyCycleDiscipline computeCycleDiscipline({
    required List<Map<String, dynamic>> executions,
    required List<String> disciplineFlags,
    required Map<String, dynamic> constraints,
  }) {
    // Base score
    double score = 100;

    // Violation buckets
    int adherenceViolations = 0;
    int timingViolations = 0;
    int riskViolations = 0;

    // 1) Flag-based penalties
    for (final flag in disciplineFlags) {
      if (flag.contains('adherence')) {
        adherenceViolations++;
        score -= 5;
      } else if (flag.contains('timing')) {
        timingViolations++;
        score -= 5;
      } else if (flag.contains('risk')) {
        riskViolations++;
        score -= 5;
      } else {
        score -= 2;
      }
    }

    // 2) Constraint-based checks (very lightweight)
    final maxRisk = (constraints['maxRisk'] ?? 0).toDouble();
    if (maxRisk > 0) {
      double estRiskTotal = 0;
      for (final e in executions) {
        final premium = (e['premium'] ?? 0).toDouble();
        final qty = (e['qty'] ?? 1).toDouble();
        estRiskTotal += premium * 100 * qty;
      }
      if (estRiskTotal > maxRisk) {
        riskViolations++;
        score -= 10;
      }
    }

    // 3) Timing heuristic: if many trades in short time, treat as timing slippage
    if (executions.length >= 3) {
      final timestamps = executions
          .map((e) => e['timestamp'])
          .whereType<DateTime>()
          .cast<DateTime>()
          .toList()
        ..sort();
      if (timestamps.length >= 3) {
        final first = timestamps.first;
        final last = timestamps.last;
        final minutes = last.difference(first).inMinutes;
        if (minutes <= 10) {
          timingViolations++;
          score -= 5;
        }
      }
    }

    if (score < 0) score = 0;
    if (score > 100) score = 100;

    final violations = <String, int>{
      'adherence': adherenceViolations,
      'timing': timingViolations,
      'risk': riskViolations,
    };

    // Streak impact: simple heuristic (you can refine later)
    final totalViolations =
        adherenceViolations + timingViolations + riskViolations;
    final streakImpact = -totalViolations;

    return StrategyCycleDiscipline(
      score: score,
      violations: violations,
      streakImpact: streakImpact,
    );
  }
}
