import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_performance_analyzer.dart';

void main() {
  test('computeCyclePerformance signs PnL for SELL vs BUY', () {
    final sellExec = [
      {'type': 'SELL', 'premium': 1.5, 'qty': 1},
    ];

    final sellRes = StrategyPerformanceAnalyzer.computeCyclePerformance(executions: sellExec);
    expect(sellRes.realizedPnl, 150.0);

    final buyExec = [
      {'type': 'BUY', 'premium': 1.5, 'qty': 1},
    ];

    final buyRes = StrategyPerformanceAnalyzer.computeCyclePerformance(executions: buyExec);
    expect(buyRes.realizedPnl, -150.0);
  });

  test('computeCyclePerformance handles multi-leg mixed executions', () {
    final execs = [
      {'type': 'SELL', 'premium': 1.5, 'qty': 1}, // +150
      {'type': 'BUY', 'premium': 0.5, 'qty': 2},  // -100
    ];

    final res = StrategyPerformanceAnalyzer.computeCyclePerformance(executions: execs);
    expect(res.realizedPnl, 50.0);
    expect(res.bestTrade?['type'], 'SELL');
    expect(res.worstTrade?['type'], 'BUY');
  });

  test('computeCyclePerformance aggregates quantities correctly', () {
    final execs = [
      {'type': 'SELL', 'premium': 2.0, 'qty': 3}, // 2.0*100*3 = 600
      {'type': 'SELL', 'premium': 0.25, 'qty': 4}, // 0.25*100*4 = 100
      {'type': 'BUY', 'premium': 1.0, 'qty': 2}, // -200
    ];

    final res = StrategyPerformanceAnalyzer.computeCyclePerformance(executions: execs);
    expect(res.realizedPnl, 500.0); // 600+100-200
  });
}
