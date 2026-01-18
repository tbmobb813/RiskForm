class StrategyRecommendation {
  final String strategyId;
  final String strategyName;
  final String reason;
  final List<String> blockingConditions;

  StrategyRecommendation({
    required this.strategyId,
    required this.strategyName,
    required this.reason,
    this.blockingConditions = const [],
  });
}
