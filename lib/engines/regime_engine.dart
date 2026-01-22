import 'dart:async';

import '../services/market_data_models.dart';
import '../services/market_data_service.dart';

/// Regime engine API
abstract class RegimeEngine {
  Future<MarketRegimeSnapshot> getRegime(String symbol);
}

class LiveRegimeEngine implements RegimeEngine {
  final MarketDataService marketData;
  final Duration cacheTtl;

  LiveRegimeEngine(this.marketData, {this.cacheTtl = const Duration(seconds: 45)});

  final Map<String, _CacheEntry<MarketRegimeSnapshot>> _cache = {};

  @override
  Future<MarketRegimeSnapshot> getRegime(String symbol) async {
    final now = DateTime.now().toUtc();
    final cached = _cache[symbol];
    if (cached != null && now.difference(cached.asOf) <= cacheTtl) {
      return cached.value;
    }

    final price = await marketData.getPrice(symbol);
    final vol = await marketData.getVolatility(symbol);
    final liq = await marketData.getLiquidity(symbol);

    final trend = classifyTrend(price);
    final volRegime = classifyVolatility(vol);
    final liqRegime = classifyLiquidity(liq);

    final snap = MarketRegimeSnapshot(
      symbol: symbol,
      trend: trend,
      volatility: volRegime,
      liquidity: liqRegime,
      asOf: DateTime.now().toUtc(),
    );

    _cache[symbol] = _CacheEntry(snap, snap.asOf);
    return snap;
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime asOf;
  _CacheEntry(this.value, this.asOf);
}

// -- Classification helpers (deterministic, pure) --

String classifyTrend(MarketPriceSnapshot p) {
  final maDiff = p.maShort - p.maLong;

  // Strong uptrend
  if (maDiff > 0 && p.trendSlope > 0 && p.changePct > 0.5) {
    return "uptrend";
  }

  // Strong downtrend
  if (maDiff < 0 && p.trendSlope < 0 && p.changePct < -0.5) {
    return "downtrend";
  }

  // Sideways band: small MA diff + low slope
  final absDiff = maDiff.abs();
  final absSlope = p.trendSlope.abs();
  if (absDiff < 0.5 * p.atr && absSlope < 0.1) {
    return "sideways";
  }

  // Fallback: MA relationship
  if (maDiff > 0) return "uptrend";
  if (maDiff < 0) return "downtrend";
  return "sideways";
}

String classifyVolatility(MarketVolatilitySnapshot v) {
  final rank = v.ivRank;
  if (rank >= 70) return "high";
  if (rank <= 30) return "low";
  return "normal";
}

String classifyLiquidity(MarketLiquiditySnapshot l) {
  final spread = l.bidAskSpread;
  final vol = l.volume;
  final oi = l.openInterest;

  // Deep: tight spread + good volume + decent OI
  if (spread <= 0.05 && vol >= 100000 && oi >= 5000) {
    return "deep";
  }

  // Thin: wide spread OR very low volume/OI
  if (spread >= 0.30 || vol < 10000 || oi < 500) {
    return "thin";
  }

  return "normal";
}
