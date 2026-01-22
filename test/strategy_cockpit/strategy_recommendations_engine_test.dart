import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_recommendations_engine.dart';

void main() {
  test('generateRecommendations returns expected categories', () {
    final ctx = StrategyContext(
      healthScore: 55,
      pnlTrend: [-0.02, -0.01, 0.01, 0.02],
      disciplineTrend: [80, 75,  fiftyMinus() /* placeholder replaced below */],
      recentCycles: [
        CycleSummary(disciplineScore: 50, pnl: -100.0, regime: 'downtrend'),
        CycleSummary(disciplineScore: 45, pnl: -50.0, regime: 'downtrend'),
      ],
      constraints: Constraints(maxRisk: 100, maxPositions: 10, allowedDteRange: [10, 60], allowedDeltaRange: [0.05, 0.5]),
      currentRegime: 'downtrend',
      drawdown: 0.2,
      backtestComparison: BacktestSummary(bestConfig: {'dte': 30, 'delta': 0.18, 'width': 'standard'}),
    );

    final bundle = generateRecommendations(ctx);

    // Expect at least one recommendation for parameter, risk, regime, discipline
    final cats = bundle.recommendations.map((r) => r.category).toSet();
    expect(cats.contains('parameter'), isTrue);
    expect(cats.contains('risk'), isTrue);
    expect(cats.contains('regime'), isTrue);
    expect(cats.contains('discipline'), isTrue);
  });
}

// Small helper to avoid a magic number in test and keep readability.
int fiftyMinus() => 50;
