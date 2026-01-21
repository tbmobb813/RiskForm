import 'dart:async';

import 'market_data_models.dart';

/// Abstract MarketDataService used by Phase 6 engines.
abstract class MarketDataService {
  /// Fetch a price snapshot for [symbol].
  Future<MarketPriceSnapshot> getPrice(String symbol);

  /// Fetch a volatility snapshot for [symbol].
  Future<MarketVolatilitySnapshot> getVolatility(String symbol);

  /// Fetch a liquidity snapshot for [symbol].
  Future<MarketLiquiditySnapshot> getLiquidity(String symbol);

  /// Fetch or compute a regime snapshot for [symbol].
  Future<MarketRegimeSnapshot> getRegime(String symbol);

  /// Optional: subscribe to periodic snapshots for UI streaming.
  /// Implementations may return a broadcast stream.
  Stream<MarketPriceSnapshot> subscribePrice(String symbol, {Duration? interval}) =>
      Stream.empty();

  Stream<MarketVolatilitySnapshot> subscribeVolatility(String symbol, {Duration? interval}) =>
      Stream.empty();

  Stream<MarketLiquiditySnapshot> subscribeLiquidity(String symbol, {Duration? interval}) =>
      Stream.empty();

  Stream<MarketRegimeSnapshot> subscribeRegime(String symbol, {Duration? interval}) =>
      Stream.empty();
}
