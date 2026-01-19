import 'discipline_score_model.dart';

class DisciplineEngine {
  static DisciplineScore scoreTrade({
    required Map<String, dynamic> plannedParams,
    required Map<String, dynamic> executedParams,
  }) {
    int adherence = _scoreAdherence(plannedParams, executedParams);
    int timing = _scoreTiming(plannedParams, executedParams);
    int risk = _scoreRisk(plannedParams, executedParams);

    int total = adherence + timing + risk;

    return DisciplineScore(
      total: total.clamp(0, 100),
      adherence: adherence,
      timing: timing,
      risk: risk,
    );
  }

  static int _scoreAdherence(Map<String, dynamic> plan, Map<String, dynamic> exec) {
    int score = 40;

    if (plan['strike'] != null && exec['strike'] != null && plan['strike'] != exec['strike']) score -= 15;
    if (plan['expiration'] != null && exec['expiration'] != null && plan['expiration'] != exec['expiration']) score -= 10;
    if (plan['contracts'] != null && exec['contracts'] != null && plan['contracts'] != exec['contracts']) score -= 15;

    return score.clamp(0, 40);
  }

  static int _scoreTiming(Map<String, dynamic> plan, Map<String, dynamic> exec) {
    int score = 30;

    final plannedTime = plan['plannedEntryTime'] as DateTime?;
    final executedTime = exec['executedAt'] as DateTime?;

    if (plannedTime != null && executedTime != null) {
      final diff = executedTime.difference(plannedTime).inMinutes.abs();
      if (diff > 30) score -= 10;
      if (diff > 60) score -= 20;
    }

    return score.clamp(0, 30);
  }

  static int _scoreRisk(Map<String, dynamic> plan, Map<String, dynamic> exec) {
    int score = 30;

    // Attempt to compute a dollar risk and compare to allowed plan risk
    final stopLoss = plan['stopLoss'] as num?; // price level
    final accountSize = (plan['accountSize'] as num?)?.toDouble() ?? 10000.0;
    final contractSize = (plan['contractSize'] as num?)?.toDouble() ?? 100.0; // shares per contract
    final execEntry = (exec['entryPrice'] as num?)?.toDouble();
    final contracts = (exec['contracts'] as num?)?.toDouble() ?? (plan['contracts'] as num?)?.toDouble() ?? 0.0;
    double positionShares = 0.0;
    if ((plan['positionSize'] as num?) != null) {
      positionShares = (plan['positionSize'] as num).toDouble();
    } else if (contracts > 0) {
      positionShares = contracts * contractSize;
    }

    double dollarRisk = 0.0;
    if (stopLoss != null && execEntry != null && positionShares > 0) {
      final lossPerShare = (execEntry - stopLoss.toDouble()).abs();
      dollarRisk = lossPerShare * positionShares;
    }

    final planMaxRiskDollar = (plan['maxRiskDollar'] as num?)?.toDouble();
    final planMaxRiskPct = (plan['maxRiskPercent'] as num?)?.toDouble();

    // If a dollar limit is set, compare directly
    if (planMaxRiskDollar != null && dollarRisk > planMaxRiskDollar) {
      score -= 15;
    }

    // If a percent limit is set, compare to account size
    if (planMaxRiskPct != null && accountSize > 0) {
      final riskPct = (dollarRisk / accountSize) * 100.0;
      if (riskPct > planMaxRiskPct) score -= 15;
    }

    // If no detailed plan risk provided, fallback to exec-provided risk if present
    final execRisk = (exec['risk'] as num?)?.toDouble();
    if (planMaxRiskDollar == null && planMaxRiskPct == null && execRisk != null) {
      // execRisk interpreted as percent
      if (execRisk > 10.0) score -= 10; // arbitrary penalty for high observed risk
    }

    return score.clamp(0, 30).toInt();
  }
}
