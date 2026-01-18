import '../../models/analytics/market_regime.dart';

class CycleStats {
  final int index;
  final double startEquity;
  final double endEquity;
  final int durationDays;
  final bool hadAssignment;
  final MarketRegime? dominantRegime;
  final int? startIndex;
  final int? endIndex;
  double get cycleReturn => (endEquity - startEquity) / startEquity;

  CycleStats({
    required this.index,
    required this.startEquity,
    required this.endEquity,
    required this.durationDays,
    required this.hadAssignment,
    this.dominantRegime,
    this.startIndex,
    this.endIndex,
  });
}

class BacktestResult {
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

  BacktestResult({
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
