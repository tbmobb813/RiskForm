// Market data snapshot DTOs used across Phase 6 engines.

class MarketPriceSnapshot {
  final String symbol;
  final double last;
  final double changePct;
  final double atr;
  final double maShort;
  final double maLong;
  final double trendSlope;
  final DateTime asOf;

  const MarketPriceSnapshot({
    required this.symbol,
    required this.last,
    required this.changePct,
    required this.atr,
    required this.maShort,
    required this.maLong,
    required this.trendSlope,
    required this.asOf,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'last': last,
        'changePct': changePct,
        'atr': atr,
        'maShort': maShort,
        'maLong': maLong,
        'trendSlope': trendSlope,
        'asOf': asOf.toIso8601String(),
      };

  factory MarketPriceSnapshot.fromJson(Map<String, dynamic> j) => MarketPriceSnapshot(
        symbol: j['symbol'] as String,
        last: (j['last'] as num).toDouble(),
        changePct: (j['changePct'] as num).toDouble(),
        atr: (j['atr'] as num).toDouble(),
        maShort: (j['maShort'] as num).toDouble(),
        maLong: (j['maLong'] as num).toDouble(),
        trendSlope: (j['trendSlope'] as num).toDouble(),
        asOf: DateTime.parse(j['asOf'] as String),
      );
}

class MarketVolatilitySnapshot {
  final String symbol;
  final double iv;
  final double ivRank;
  final double ivPercentile;
  final double? vixLevel;
  final DateTime asOf;

  const MarketVolatilitySnapshot({
    required this.symbol,
    required this.iv,
    required this.ivRank,
    required this.ivPercentile,
    this.vixLevel,
    required this.asOf,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'iv': iv,
        'ivRank': ivRank,
        'ivPercentile': ivPercentile,
        'vixLevel': vixLevel,
        'asOf': asOf.toIso8601String(),
      };

  factory MarketVolatilitySnapshot.fromJson(Map<String, dynamic> j) => MarketVolatilitySnapshot(
        symbol: j['symbol'] as String,
        iv: (j['iv'] as num).toDouble(),
        ivRank: (j['ivRank'] as num).toDouble(),
        ivPercentile: (j['ivPercentile'] as num).toDouble(),
        vixLevel: j['vixLevel'] == null ? null : (j['vixLevel'] as num).toDouble(),
        asOf: DateTime.parse(j['asOf'] as String),
      );
}

class MarketLiquiditySnapshot {
  final String symbol;
  final double bidAskSpread;
  final int volume;
  final int openInterest;
  final double slippageEstimate;
  final DateTime asOf;

  const MarketLiquiditySnapshot({
    required this.symbol,
    required this.bidAskSpread,
    required this.volume,
    required this.openInterest,
    required this.slippageEstimate,
    required this.asOf,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'bidAskSpread': bidAskSpread,
        'volume': volume,
        'openInterest': openInterest,
        'slippageEstimate': slippageEstimate,
        'asOf': asOf.toIso8601String(),
      };

  factory MarketLiquiditySnapshot.fromJson(Map<String, dynamic> j) => MarketLiquiditySnapshot(
        symbol: j['symbol'] as String,
        bidAskSpread: (j['bidAskSpread'] as num).toDouble(),
        volume: (j['volume'] as num).toInt(),
        openInterest: (j['openInterest'] as num).toInt(),
        slippageEstimate: (j['slippageEstimate'] as num).toDouble(),
        asOf: DateTime.parse(j['asOf'] as String),
      );
}

class MarketRegimeSnapshot {
  final String symbol;
  final String trend; // "uptrend", "downtrend", "sideways"
  final String volatility; // "low", "normal", "high"
  final String liquidity; // "thin", "normal", "deep"
  final DateTime asOf;

  const MarketRegimeSnapshot({
    required this.symbol,
    required this.trend,
    required this.volatility,
    required this.liquidity,
    required this.asOf,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'trend': trend,
        'volatility': volatility,
        'liquidity': liquidity,
        'asOf': asOf.toIso8601String(),
      };

  factory MarketRegimeSnapshot.fromJson(Map<String, dynamic> j) => MarketRegimeSnapshot(
        symbol: j['symbol'] as String,
        trend: j['trend'] as String,
        volatility: j['volatility'] as String,
        liquidity: j['liquidity'] as String,
        asOf: DateTime.parse(j['asOf'] as String),
      );
}
