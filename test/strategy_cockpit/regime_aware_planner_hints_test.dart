import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/strategy_cockpit/analytics/regime_aware_planner_hints.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_recommendations_engine.dart';

void main() {
  test('generateHints recommends tighter delta on uptrend and applies backtest ranges', () {
    final ctx = StrategyContext(
      healthScore: 80,
      pnlTrend: [1.0, 0.5, 0.8],
      disciplineTrend: [80, 82, 85],
      recentCycles: const [],
      constraints: const Constraints(maxRisk: 100, maxPositions: 5),
      currentRegime: 'uptrend',
      drawdown: 0.02,
      backtestComparison: BacktestSummary(bestConfig: {'dte': 30, 'delta': 0.18, 'width': 20}),
    );

    final state = PlannerState(dte: 25, delta: 0.22, width: 15.0, size: 2, type: 'credit_spread');

    final bundle = generateHints(state, ctx);

    // expect a delta recommended range from regime and backtest; backtest should set exact values
    expect(bundle.recommendedRanges.containsKey('delta'), isTrue);
    final deltaRange = bundle.recommendedRanges['delta']!;
    expect(deltaRange.start <= 0.18 && deltaRange.end >= 0.18, isTrue);

    // expect an info hint about uptrend
    expect(bundle.hints.any((h) => h.field == 'delta' && h.message.toLowerCase().contains('uptrend')), isTrue);
    // expect backtest info present
    expect(bundle.hints.any((h) => h.field == 'backtest'), isTrue);
  });

  test('generateHints warns when delta outside constraints', () {
    final ctx = StrategyContext(
      healthScore: 70,
      pnlTrend: [0.2, -0.1],
      disciplineTrend: [65, 64],
      recentCycles: const [],
      constraints: const Constraints(maxRisk: 100, maxPositions: 3, allowedDeltaRange: [0.05, 0.2]),
      currentRegime: 'sideways',
      drawdown: 0.05,
    );

    final state = PlannerState(dte: 40, delta: 0.25, width: 10.0, size: 1, type: 'strangle');

    final bundle = generateHints(state, ctx);

    expect(bundle.hints.any((h) => h.severity == 'danger' && h.field == 'delta'), isTrue);
    expect(bundle.recommendedRanges['delta']!.start <= 0.2, isTrue);
  });
}
