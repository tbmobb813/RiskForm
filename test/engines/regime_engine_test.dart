import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/engines/regime_engine.dart';
import 'package:riskform/services/market_data_models.dart';
import 'package:riskform/services/mock_market_data_service.dart';

void main() {
  group('classification helpers', () {
    test('classifyTrend detects uptrend', () {
      final snap = MarketPriceSnapshot(
        symbol: 'TST',
        last: 120.0,
        changePct: 1.0,
        atr: 1.0,
        maShort: 105.0,
        maLong: 100.0,
        trendSlope: 0.2,
        asOf: DateTime.now(),
      );
      expect(classifyTrend(snap), 'uptrend');
    });

    test('classifyTrend detects downtrend', () {
      final snap = MarketPriceSnapshot(
        symbol: 'TST',
        last: 80.0,
        changePct: -1.0,
        atr: 1.0,
        maShort: 95.0,
        maLong: 100.0,
        trendSlope: -0.2,
        asOf: DateTime.now(),
      );
      expect(classifyTrend(snap), 'downtrend');
    });

    test('classifyTrend detects sideways', () {
      final snap = MarketPriceSnapshot(
        symbol: 'TST',
        last: 100.0,
        changePct: 0.0,
        atr: 10.0,
        maShort: 101.0,
        maLong: 100.5,
        trendSlope: 0.02,
        asOf: DateTime.now(),
      );
      expect(classifyTrend(snap), 'sideways');
    });

    test('classifyVolatility high/low/normal', () {
      final high = MarketVolatilitySnapshot(symbol: 'T', iv: 0.5, ivRank: 80, ivPercentile: 80, vixLevel: null, asOf: DateTime.now());
      final low = MarketVolatilitySnapshot(symbol: 'T', iv: 0.1, ivRank: 20, ivPercentile: 20, vixLevel: null, asOf: DateTime.now());
      final norm = MarketVolatilitySnapshot(symbol: 'T', iv: 0.3, ivRank: 50, ivPercentile: 50, vixLevel: null, asOf: DateTime.now());

      expect(classifyVolatility(high), 'high');
      expect(classifyVolatility(low), 'low');
      expect(classifyVolatility(norm), 'normal');
    });

    test('classifyLiquidity deep/normal/thin', () {
      final deep = MarketLiquiditySnapshot(symbol: 'T', bidAskSpread: 0.02, volume: 200000, openInterest: 6000, slippageEstimate: 0.0005, asOf: DateTime.now());
      final thin = MarketLiquiditySnapshot(symbol: 'T', bidAskSpread: 0.5, volume: 5000, openInterest: 100, slippageEstimate: 0.05, asOf: DateTime.now());
      final normal = MarketLiquiditySnapshot(symbol: 'T', bidAskSpread: 0.1, volume: 50000, openInterest: 2000, slippageEstimate: 0.005, asOf: DateTime.now());

      expect(classifyLiquidity(deep), 'deep');
      expect(classifyLiquidity(thin), 'thin');
      expect(classifyLiquidity(normal), 'normal');
    });
  });

  group('LiveRegimeEngine integration', () {
    test('getRegime uses market data snapshots and classifies', () async {
      final price = MarketPriceSnapshot(symbol: 'ABC', last: 150, changePct: 1.2, atr: 2.0, maShort: 110, maLong: 100, trendSlope: 0.3, asOf: DateTime.now());
      final vol = MarketVolatilitySnapshot(symbol: 'ABC', iv: 0.4, ivRank: 75, ivPercentile: 75, vixLevel: null, asOf: DateTime.now());
      final liq = MarketLiquiditySnapshot(symbol: 'ABC', bidAskSpread: 0.02, volume: 200000, openInterest: 6000, slippageEstimate: 0.0005, asOf: DateTime.now());

      final mock = MockMarketDataService(prices: {'ABC': price}, vols: {'ABC': vol}, liqs: {'ABC': liq});
      final engine = LiveRegimeEngine(mock);

      final regime = await engine.getRegime('ABC');
      expect(regime.trend, 'uptrend');
      expect(regime.volatility, 'high');
      expect(regime.liquidity, 'deep');
    });
  });
}
