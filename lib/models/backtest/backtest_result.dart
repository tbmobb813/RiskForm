import '../../models/analytics/market_regime.dart';
import '../../models/analytics/regime_segment.dart';
import 'backtest_config.dart';
import '../../utils/parse_date.dart' as pd;

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

  Map<String, dynamic> toMap() {
    return {
      'cycleId': cycleId,
      'index': index,
      'startEquity': startEquity,
      'endEquity': endEquity,
      'durationDays': durationDays,
      'hadAssignment': hadAssignment,
      'outcome': outcome?.toString(),
      'dominantRegime': dominantRegime?.toString(),
      'startIndex': startIndex,
      'endIndex': endIndex,
      'assignmentPrice': assignmentPrice,
      'assignmentStrike': assignmentStrike,
      'calledAwayPrice': calledAwayPrice,
      'calledAwayStrike': calledAwayStrike,
    };
  }

  factory CycleStats.fromMap(Map<String, dynamic> m) {
    MarketRegime? regime;
    if (m['dominantRegime'] != null) {
      final s = (m['dominantRegime'] as String).split('.').last;
      regime = MarketRegime.values.firstWhere((e) => e.toString().split('.').last == s);
    }

    CycleOutcome? outcome;
    if (m['outcome'] != null) {
      final s = (m['outcome'] as String).split('.').last;
      outcome = CycleOutcome.values.firstWhere((e) => e.toString().split('.').last == s);
    }

    return CycleStats(
      cycleId: m['cycleId'] as String,
      index: (m['index'] as num).toInt(),
      startEquity: (m['startEquity'] as num).toDouble(),
      endEquity: (m['endEquity'] as num).toDouble(),
      durationDays: (m['durationDays'] as num).toInt(),
      hadAssignment: m['hadAssignment'] as bool,
      outcome: outcome,
      dominantRegime: regime,
      startIndex: m['startIndex'] as int?,
      endIndex: m['endIndex'] as int?,
      assignmentPrice: (m['assignmentPrice'] as num?)?.toDouble(),
      assignmentStrike: (m['assignmentStrike'] as num?)?.toDouble(),
      calledAwayPrice: (m['calledAwayPrice'] as num?)?.toDouble(),
      calledAwayStrike: (m['calledAwayStrike'] as num?)?.toDouble(),
    );
  }
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
  final String engineVersion;
  final List<RegimeSegment> regimeSegments;

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
    this.engineVersion = '1.0.0',
    this.regimeSegments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'configUsed': configUsed.toMap(),
      'equityCurve': equityCurve,
      'maxDrawdown': maxDrawdown,
      'totalReturn': totalReturn,
      'cyclesCompleted': cyclesCompleted,
      'notes': notes,
      'cycles': cycles.map((c) => c.toMap()).toList(),
      'avgCycleReturn': avgCycleReturn,
      'avgCycleDurationDays': avgCycleDurationDays,
      'assignmentRate': assignmentRate,
      'uptrendAvgCycleReturn': uptrendAvgCycleReturn,
      'downtrendAvgCycleReturn': downtrendAvgCycleReturn,
      'sidewaysAvgCycleReturn': sidewaysAvgCycleReturn,
      'uptrendAssignmentRate': uptrendAssignmentRate,
      'downtrendAssignmentRate': downtrendAssignmentRate,
      'sidewaysAssignmentRate': sidewaysAssignmentRate,
      'engineVersion': engineVersion,
      'regimeSegments': regimesToMap(),
    };
  }

  List<Map<String, dynamic>> regimesToMap() {
    return regimeSegments.map((s) => {
          'regime': s.regime.toString(),
          'startDate': s.startDate.toIso8601String(),
          'endDate': s.endDate.toIso8601String(),
          'startIndex': s.startIndex,
          'endIndex': s.endIndex,
        }).toList();
  }

  factory BacktestResult.fromMap(Map<String, dynamic> m) {
    return BacktestResult(
      configUsed: BacktestConfig.fromMap(Map<String, dynamic>.from(m['configUsed'] as Map)),
      equityCurve: List<double>.from((m['equityCurve'] as List).map((e) => (e as num).toDouble())),
      maxDrawdown: (m['maxDrawdown'] as num).toDouble(),
      totalReturn: (m['totalReturn'] as num).toDouble(),
      cyclesCompleted: (m['cyclesCompleted'] as num).toInt(),
      notes: List<String>.from(m['notes'] as List<dynamic>),
      cycles: List<Map<String, dynamic>>.from(m['cycles'] as List<dynamic>).map((c) => CycleStats.fromMap(c)).toList(),
      avgCycleReturn: (m['avgCycleReturn'] as num).toDouble(),
      avgCycleDurationDays: (m['avgCycleDurationDays'] as num).toDouble(),
      assignmentRate: (m['assignmentRate'] as num).toDouble(),
      uptrendAvgCycleReturn: (m['uptrendAvgCycleReturn'] as num).toDouble(),
      downtrendAvgCycleReturn: (m['downtrendAvgCycleReturn'] as num).toDouble(),
      sidewaysAvgCycleReturn: (m['sidewaysAvgCycleReturn'] as num).toDouble(),
      uptrendAssignmentRate: (m['uptrendAssignmentRate'] as num).toDouble(),
      downtrendAssignmentRate: (m['downtrendAssignmentRate'] as num).toDouble(),
      sidewaysAssignmentRate: (m['sidewaysAssignmentRate'] as num).toDouble(),
      engineVersion: m['engineVersion'] as String? ?? '1.0.0',
      regimeSegments: (m['regimeSegments'] as List<dynamic>?)
              ?.map((s) => RegimeSegment(
                    regime: MarketRegime.values.firstWhere((e) => e.toString() == (s['regime'] as String)),
                    startDate: pd.parseDate(s['startDate'])!,
                    endDate: pd.parseDate(s['endDate'])!,
                    startIndex: (s['startIndex'] as num).toInt(),
                    endIndex: (s['endIndex'] as num).toInt(),
                  ))
              .toList() ?? [],
    );
  }
}
