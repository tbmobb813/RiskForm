import '../../models/analytics/market_regime.dart';
import 'backtest_config.dart';

/// Represents the outcome of a wheel cycle.
enum CycleOutcome {
  expiredOTM,
  assigned,
  calledAway,
}

class CycleStats {
  final String cycleId;
  final int index;
  final double startEquity;
  final double endEquity;
  final int durationDays;
  final bool hadAssignment;
  final CycleOutcome? outcome;
  final MarketRegime? dominantRegime;
  final int? startIndex;
  final int? endIndex;

  // Assignment details (populated when CSP is assigned)
  final double? assignmentPrice;
  final double? assignmentStrike;

  // Called-away details (populated when CC is called away)
  final double? calledAwayPrice;
  final double? calledAwayStrike;

  double get cycleReturn => (endEquity - startEquity) / startEquity;

  CycleStats({
    required this.cycleId,
    required this.index,
    required this.startEquity,
    required this.endEquity,
    required this.durationDays,
    required this.hadAssignment,
    this.outcome,
    this.dominantRegime,
    this.startIndex,
    this.endIndex,
    this.assignmentPrice,
    this.assignmentStrike,
    this.calledAwayPrice,
    this.calledAwayStrike,
  });
}

class BacktestResult {
  final BacktestConfig configUsed;
  final List<double> equityCurve;
  final double maxDrawdown;
  final double totalReturn;
  final int cyclesCompleted;
  final List<String> notes;

  // cycle analytics
  final List<CycleStats> cycles;
  final double avgCycleReturn;
  final double avgCycleDurationDays;
  final double assignmentRate; // 0..1
  // regime-level aggregates
  final double uptrendAvgCycleReturn;
  final double downtrendAvgCycleReturn;
  final double sidewaysAvgCycleReturn;

  final double uptrendAssignmentRate;
  final double downtrendAssignmentRate;
  final double sidewaysAssignmentRate;

  /// Convenience getter for strategyId from config.
  String get strategyId => configUsed.strategyId;

  BacktestResult({
    required this.configUsed,
    required this.equityCurve,
    required this.maxDrawdown,
    required this.totalReturn,
    required this.cyclesCompleted,
    required this.notes,
    required this.cycles,
    required this.avgCycleReturn,
    required this.avgCycleDurationDays,
    required this.assignmentRate,
    required this.uptrendAvgCycleReturn,
    required this.downtrendAvgCycleReturn,
    required this.sidewaysAvgCycleReturn,
    required this.uptrendAssignmentRate,
    required this.downtrendAssignmentRate,
    required this.sidewaysAssignmentRate,
  });
}
