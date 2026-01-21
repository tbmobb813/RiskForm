import 'dart:async';

import 'market_data_models.dart';
import 'market_data_service.dart';

/// A minimal, deterministic MockMarketDataService for tests and local development.
class MockMarketDataService implements MarketDataService {
  final Map<String, MarketPriceSnapshot> _priceMap;
  final Map<String, MarketVolatilitySnapshot> _volMap;
  final Map<String, MarketLiquiditySnapshot> _liqMap;
  final Map<String, MarketRegimeSnapshot> _regimeMap;

  MockMarketDataService({
    Map<String, MarketPriceSnapshot>? prices,
    Map<String, MarketVolatilitySnapshot>? vols,
    Map<String, MarketLiquiditySnapshot>? liqs,
    Map<String, MarketRegimeSnapshot>? regimes,
  })  : _priceMap = prices ?? {},
        _volMap = vols ?? {},
        _liqMap = liqs ?? {},
        _regimeMap = regimes ?? {};

  @override
  Future<MarketPriceSnapshot> getPrice(String symbol) async {
    final now = DateTime.now().toUtc();
    return _priceMap[symbol] ?? MarketPriceSnapshot(
      symbol: symbol,
      last: 100.0,
      changePct: 0.0,
      atr: 1.0,
      maShort: 99.0,
      maLong: 98.0,
      trendSlope: 0.0,
      asOf: now,
    );
  }

  @override
  Future<MarketVolatilitySnapshot> getVolatility(String symbol) async {
    final now = DateTime.now().toUtc();
    return _volMap[symbol] ?? MarketVolatilitySnapshot(
      symbol: symbol,
      iv: 0.35,
      ivRank: 50.0,
      ivPercentile: 50.0,
      vixLevel: null,
      asOf: now,
    );
  }

  @override
  Future<MarketLiquiditySnapshot> getLiquidity(String symbol) async {
    final now = DateTime.now().toUtc();
    return _liqMap[symbol] ?? MarketLiquiditySnapshot(
      symbol: symbol,
      bidAskSpread: 0.05,
      volume: 100000,
      openInterest: 50000,
      slippageEstimate: 0.001,
      asOf: now,
    );
  }

  @override
  Future<MarketRegimeSnapshot> getRegime(String symbol) async {
    final now = DateTime.now().toUtc();
    return _regimeMap[symbol] ?? MarketRegimeSnapshot(
      symbol: symbol,
      trend: 'sideways',
      volatility: 'normal',
      liquidity: 'normal',
      asOf: now,
    );
  }

  @override
  Stream<MarketPriceSnapshot> subscribePrice(String symbol, {Duration? interval}) {
    final dur = interval ?? const Duration(seconds: 5);
    return Stream<MarketPriceSnapshot>.periodic(dur, (_) => _priceMap[symbol] ?? MarketPriceSnapshot(
      symbol: symbol,
      last: 100.0,
      changePct: 0.0,
      atr: 1.0,
      maShort: 99.0,
      maLong: 98.0,
      trendSlope: 0.0,
      asOf: DateTime.now().toUtc(),
    ))..asBroadcastStream();
  }

  @override
  Stream<MarketVolatilitySnapshot> subscribeVolatility(String symbol, {Duration? interval}) {
    final dur = interval ?? const Duration(seconds: 30);
    return Stream<MarketVolatilitySnapshot>.periodic(dur, (_) => _volMap[symbol] ?? MarketVolatilitySnapshot(
      symbol: symbol,
      iv: 0.35,
      ivRank: 50.0,
      ivPercentile: 50.0,
      vixLevel: null,
      asOf: DateTime.now().toUtc(),
    ))..asBroadcastStream();
  }

  @override
  Stream<MarketLiquiditySnapshot> subscribeLiquidity(String symbol, {Duration? interval}) {
    final dur = interval ?? const Duration(seconds: 30);
    return Stream<MarketLiquiditySnapshot>.periodic(dur, (_) => _liqMap[symbol] ?? MarketLiquiditySnapshot(
      symbol: symbol,
      bidAskSpread: 0.05,
      volume: 100000,
      openInterest: 50000,
      slippageEstimate: 0.001,
      asOf: DateTime.now().toUtc(),
    ))..asBroadcastStream();
  }

  @override
  Stream<MarketRegimeSnapshot> subscribeRegime(String symbol, {Duration? interval}) {
    final dur = interval ?? const Duration(seconds: 60);
    return Stream<MarketRegimeSnapshot>.periodic(dur, (_) => _regimeMap[symbol] ?? MarketRegimeSnapshot(
      symbol: symbol,
      trend: 'sideways',
      volatility: 'normal',
      liquidity: 'normal',
      asOf: DateTime.now().toUtc(),
    ))..asBroadcastStream();
  }
}
