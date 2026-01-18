import 'wheel_cycle.dart';

class StrategyRecommendation {
  final String strategyId;
  final String strategyName;
  final String action;
  final String reason;
  final WheelCycleState? wheelState;
  final List<String> blockingConditions;

  StrategyRecommendation({
    required this.strategyId,
    required this.strategyName,
    required this.action,
    required this.reason,
    this.wheelState,
    this.blockingConditions = const [],
  });
}
