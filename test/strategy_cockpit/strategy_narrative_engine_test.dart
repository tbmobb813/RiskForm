import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_narrative_engine.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_recommendations_engine.dart';

void main() {
  test('generateNarrative produces a summary and bullets for basic context', () {
    final ctx = StrategyContext(
      healthScore: 80,
      pnlTrend: [0.5, 0.2, 0.3],
      disciplineTrend: [70, 72, 75],
      recentCycles: [
        CycleSummary(disciplineScore: 75, pnl: 1.2, regime: 'sideways'),
        CycleSummary(disciplineScore: 72, pnl: 0.8, regime: 'sideways'),
      ],
      constraints: Constraints(maxRisk: 100, maxPositions: 5),
      currentRegime: 'sideways',
      drawdown: 0.02,
      backtestComparison: BacktestSummary(bestConfig: {'dte': 30, 'delta': 0.18}, weakConfig: null),
    );

    final narrative = generateNarrative(ctx);
      // add a sample recommendation bundle and re-generate with recommendations
      final recBundle = StrategyRecommendationsBundle(
        generatedAt: DateTime.now(),
        recommendations: [
          StrategyRecommendation(category: 'parameter', message: 'Tighten delta to 0.15–0.20', priority: 2),
        ],
      );

      final narrativeWithRec = generateNarrative(ctx, recsBundle: recBundle);

      expect(narrativeWithRec.title.isNotEmpty, isTrue);
      expect(narrativeWithRec.summary.toLowerCase().contains('sideways'), isTrue);
      expect(narrativeWithRec.bullets.isNotEmpty, isTrue);
      expect(narrativeWithRec.outlook.isNotEmpty, isTrue);
      // ensure recommendation made it into bullets or outlook
      final joined = '${narrativeWithRec.bullets.join(' ')} ${narrativeWithRec.outlook}';
      expect(joined.contains('Tighten delta'), isTrue);
  });
}
