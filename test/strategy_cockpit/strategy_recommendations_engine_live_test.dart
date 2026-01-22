import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_recommendations_engine.dart';
import 'package:riskform/services/market_data_models.dart';

void main() {
  final engine = StrategyRecommendationsEngine();

  test('Scenario A: Uptrend, high vol, deep liquidity produces parameter + widen recs', () async {
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

    final bundle = await engine.generate(context: ctx, regime: regime, vol: vol, liq: liq);

    final msgs = bundle.recommendations.map((r) => r.message).join(' || ');
    expect(msgs.contains('delta') || msgs.contains('raising target delta') || msgs.contains('premium selling'), isTrue);
  });

  test('Scenario B: Downtrend, high vol, thin liquidity yields defensive/risk-first recommendations', () async {
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

    final bundle = await engine.generate(context: ctx, regime: regime, vol: vol, liq: liq);

    // Expect at least one high-priority risk recommendation
    final riskRecs = bundle.recommendations.where((r) => r.category == 'risk').toList();
    expect(riskRecs.isNotEmpty, isTrue);
    expect(riskRecs.any((r) => r.priority == 1), isTrue);
    final msgs = riskRecs.map((r) => r.message).join(' || ');
    expect(msgs.contains('Reduce') || msgs.contains('reduce') || msgs.contains('Thin liquidity') || msgs.contains('slippage'), isTrue);
  });
}
