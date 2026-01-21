import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_narrative_engine.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_recommendations_engine.dart';
import 'package:riskform/services/market_data_models.dart';

void main() {
  final engine = StrategyNarrativeEngine();
  final recEngine = StrategyRecommendationsEngine();

  test('Scenario A narrative includes uptrend high-volatility phrase and actionable rec', () async {
    final ctx = StrategyContext(
      healthScore: 80,
      pnlTrend: [0.01, 0.02, 0.03],
      disciplineTrend: [80, 85, 90],
      recentCycles: [],
      constraints: Constraints(maxRisk: 100, maxPositions: 5),
      currentRegime: 'uptrend',
      drawdown: 0.05,
      backtestComparison: BacktestSummary(bestConfig: {'delta': 0.05, 'dte': 30, 'width': 1}),
    );

    final regime = MarketRegimeSnapshot(symbol: 'TST', trend: 'uptrend', volatility: 'high', liquidity: 'deep', asOf: DateTime.now());
    final vol = MarketVolatilitySnapshot(symbol: 'TST', iv: 0.5, ivRank: 75, ivPercentile: 0.75, vixLevel: null, asOf: DateTime.now());
    final liq = MarketLiquiditySnapshot(symbol: 'TST', bidAskSpread: 0.01, volume: 100000, openInterest: 50000, slippageEstimate: 0.001, asOf: DateTime.now());

    final recs = await recEngine.generate(context: ctx, regime: regime, vol: vol, liq: liq);
    final narrative = engine.generate(context: ctx, recs: recs, regime: regime, vol: vol, liq: liq);

    expect(narrative.summary.toLowerCase(), contains('uptrend'));
    expect(narrative.summary.toLowerCase(), contains('high'));
    expect(narrative.bullets.any((b) => b.toLowerCase().contains('iv rank')), isTrue);
    expect(narrative.outlook.toLowerCase(), contains('actionable'));
  });

  test('Scenario B narrative flags downtrend high vol thin liquidity and recommends risk-first actions', () async {
    final ctx = StrategyContext(
      healthScore: 40,
      pnlTrend: [-0.02, -0.01, -0.03],
      disciplineTrend: [60, 55, 50],
      recentCycles: [CycleSummary(disciplineScore: 50, pnl: -100.0, regime: 'downtrend')],
      constraints: Constraints(maxRisk: 100, maxPositions: 3),
      currentRegime: 'downtrend',
      drawdown: 0.25,
      backtestComparison: BacktestSummary(bestConfig: {'delta': 0.2, 'dte': 45}),
    );

    final regime = MarketRegimeSnapshot(symbol: 'TST', trend: 'downtrend', volatility: 'high', liquidity: 'thin', asOf: DateTime.now());
    final vol = MarketVolatilitySnapshot(symbol: 'TST', iv: 0.8, ivRank: 85, ivPercentile: 0.9, vixLevel: null, asOf: DateTime.now());
    final liq = MarketLiquiditySnapshot(symbol: 'TST', bidAskSpread: 0.10, volume: 1000, openInterest: 200, slippageEstimate: 0.02, asOf: DateTime.now());

    final recs = await recEngine.generate(context: ctx, regime: regime, vol: vol, liq: liq);
    final narrative = engine.generate(context: ctx, recs: recs, regime: regime, vol: vol, liq: liq);

    expect(narrative.summary.toLowerCase(), contains('downtrend'));
    expect(narrative.bullets.any((b) => b.toLowerCase().contains('bid/ask') || b.toLowerCase().contains('slippage')), isTrue);
    expect(narrative.outlook.toLowerCase(), contains('actionable'));
    // Expect at least one recommendation referencing reduction/size or risk
    expect(recs.recommendations.any((r) => r.category == 'risk' || r.message.toLowerCase().contains('reduce')), isTrue);
  });
}
