import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/strategy_cockpit/models/strategy_health_snapshot.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_performance_analyzer.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_discipline_analyzer.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_regime_analyzer.dart';

void main() {
  group('StrategyPerformanceAnalyzer', () {
    final snapshot = StrategyHealthSnapshot(
      strategyId: 's1',
      pnlTrend: [0, 10, 5, 15, 10],
      disciplineTrend: [80, 85, 70],
      regimePerformance: {},
      cycleSummaries: [
        {'id': 'c1', 'pnl': 10},
        {'id': 'c2', 'pnl': -5},
        {'id': 'c3', 'pnl': 15},
      ],
      regimeWeaknesses: [],
      currentRegime: null,
      currentRegimeHint: null,
      updatedAt: DateTime.now(),
    );

    test('computeWinRate', () {
      final winRate = StrategyPerformanceAnalyzer.computeWinRate(snapshot);
      expect(winRate, closeTo(2 / 3, 0.0001));
    });

    test('computeMaxDrawdown', () {
      final dd = StrategyPerformanceAnalyzer.computeMaxDrawdown(snapshot);
      // Observed max drawdown in the trend is 5
      expect(dd, closeTo(5, 0.0001));
    });
  });

  group('StrategyDisciplineAnalyzer', () {
    final snapshot = StrategyHealthSnapshot(
      strategyId: 's2',
      pnlTrend: [],
      disciplineTrend: [90, 85, 70, 60],
      regimePerformance: {},
      cycleSummaries: [
        {
          'id': 'c1',
          'disciplineScore': 90,
          'disciplineBreakdown': {'adherence': 40, 'timing': 30, 'risk': 25}
        },
        {
          'id': 'c2',
          'disciplineScore': 85,
          'disciplineBreakdown': {'adherence': 35, 'timing': 25, 'risk': 30}
        },
      ],
      regimeWeaknesses: [],
      currentRegime: null,
      currentRegimeHint: null,
      updatedAt: DateTime.now(),
    );

    test('getTrend', () {
      expect(StrategyDisciplineAnalyzer.getTrend(snapshot), snapshot.disciplineTrend);
    });

    test('computeCleanCycleStreak', () {
      final streak = StrategyDisciplineAnalyzer.computeCleanCycleStreak(snapshot);
      expect(streak, 2);
    });
  });

  group('StrategyRegimeAnalyzer', () {
    final snapshot = StrategyHealthSnapshot(
      strategyId: 's3',
      pnlTrend: [],
      disciplineTrend: [],
      regimePerformance: {},
      cycleSummaries: [
        {'id': 'c1', 'regime': 'uptrend', 'pnl': 10, 'disciplineScore': 80},
        {'id': 'c2', 'regime': 'downtrend', 'pnl': -5, 'disciplineScore': 60},
        {'id': 'c3', 'regime': 'uptrend', 'pnl': 5, 'disciplineScore': 75},
      ],
      regimeWeaknesses: [],
      currentRegime: null,
      currentRegimeHint: null,
      updatedAt: DateTime.now(),
    );

    test('computeRegimePerformance', () {
      final perf = StrategyRegimeAnalyzer.computeRegimePerformance(snapshot);
      expect(perf.containsKey('uptrend'), isTrue);
      expect(perf['uptrend']!['count'], 2);
      expect(perf['downtrend']!['count'], 1);
    });
  });
}
