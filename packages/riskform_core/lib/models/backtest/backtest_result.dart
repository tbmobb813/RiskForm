import '../../models/analytics/market_regime.dart';
import '../../models/analytics/regime_segment.dart';
import 'backtest_config.dart';

enum CycleOutcome { expiredOTM, assigned, calledAway }

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

  final double? assignmentPrice;
  final double? assignmentStrike;

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
    final dynRegime = m['dominantRegime'];
    if (dynRegime != null) {
      String s;
      if (dynRegime is String) {
        s = dynRegime.split('.').last;
      } else if (dynRegime is MarketRegime) {
        s = dynRegime.toString().split('.').last;
      } else if (dynRegime is Map && dynRegime['regime'] is String) {
        s = (dynRegime['regime'] as String).split('.').last;
      } else {
        s = dynRegime.toString();
      }
      try {
        regime = MarketRegime.values.firstWhere((e) => e.toString().split('.').last == s);
      } catch (_) {
        regime = null;
      }
    }

    CycleOutcome? outcome;
    final dynOutcome = m['outcome'];
    if (dynOutcome != null) {
      String s;
      if (dynOutcome is String) {
        s = dynOutcome.split('.').last;
      } else if (dynOutcome is CycleOutcome) {
        s = dynOutcome.toString().split('.').last;
      } else {
        s = dynOutcome.toString();
      }
      try {
        outcome = CycleOutcome.values.firstWhere((e) => e.toString().split('.').last == s);
      } catch (_) {
        outcome = null;
      }
    }

    return CycleStats(
      cycleId: m['cycleId']?.toString() ?? '',
      index: (m['index'] as num?)?.toInt() ?? 0,
      startEquity: (m['startEquity'] as num?)?.toDouble() ?? 0.0,
      endEquity: (m['endEquity'] as num?)?.toDouble() ?? 0.0,
      durationDays: (m['durationDays'] as num?)?.toInt() ?? 0,
      hadAssignment: m['hadAssignment'] as bool? ?? false,
      outcome: outcome,
      dominantRegime: regime,
      startIndex: (m['startIndex'] as num?)?.toInt(),
      endIndex: (m['endIndex'] as num?)?.toInt(),
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

  final List<CycleStats> cycles;
  final double avgCycleReturn;
  final double avgCycleDurationDays;
  final double assignmentRate;
  final double uptrendAvgCycleReturn;
  final double downtrendAvgCycleReturn;
  final double sidewaysAvgCycleReturn;

  final double uptrendAssignmentRate;
  final double downtrendAssignmentRate;
  final double sidewaysAssignmentRate;
  final String engineVersion;
  final List<RegimeSegment> regimeSegments;

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
      'regimeSegments': regimeSegments.map((s) => {
            'regime': s.regime.toString(),
            'startDate': s.startDate.toIso8601String(),
            'endDate': s.endDate.toIso8601String(),
            'startIndex': s.startIndex,
            'endIndex': s.endIndex,
          }).toList(),
    };
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    throw ArgumentError('Invalid date: $v');
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
                    startDate: _parseDate(s['startDate']),
                    endDate: _parseDate(s['endDate']),
                    startIndex: (s['startIndex'] as num).toInt(),
                    endIndex: (s['endIndex'] as num).toInt(),
                  ))
              .toList() ?? [],
    );
  }
}
