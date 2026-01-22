# Phase 6.1 — Market Data Architecture
### Production Specification — Final Version

## 1. Purpose

Phase 6.1 defines the **Market Data Architecture** that feeds:

- Regime engine
- Planner hints
- Recommendations engine
- Narrative engine

with **live, symbol‑aware context** (price, volatility, liquidity) in a way that is:

- Deterministic
- Cacheable
- Testable
- Easy to mock

This is the **single source of truth** for live market context.

## 2. High‑level design

### 2.1 Core idea

You don’t scatter API calls across the app.

You define a **single MarketDataService** that:

- Knows how to fetch raw data from providers
- Normalizes it into internal models
- Caches it per symbol + timeframe
- Exposes **pure read APIs** to the rest of the system

Everything else (RegimeEngine, PlannerHints, Recommendations, Narrative) consumes **these models**, not raw APIs.

## 3. Core models

### 3.1 MarketPriceSnapshot

```dart
class MarketPriceSnapshot {
  final String symbol;
  final double last;
  final double changePct;      // daily %
  final double atr;            // e.g. 14-day ATR
  final double maShort;        // e.g. 20 SMA
  final double maLong;         // e.g. 50 SMA
  final double trendSlope;     // normalized slope
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
}
```

### 3.2 MarketVolatilitySnapshot

```dart
class MarketVolatilitySnapshot {
  final String symbol;
  final double iv;             // current IV
  final double ivRank;         // 0–100
  final double ivPercentile;   // 0–100
  final double vixLevel;       // optional, index-level
  final DateTime asOf;

  const MarketVolatilitySnapshot({
    required this.symbol,
    required this.iv,
    required this.ivRank,
    required this.ivPercentile,
    required this.vixLevel,
    required this.asOf,
  });
}
```

### 3.3 MarketLiquiditySnapshot

```dart
class MarketLiquiditySnapshot {
  final String symbol;
  final double bidAskSpread;   // in $
  final int volume;
  final int openInterest;
  final double slippageEstimate; // normalized 0–1
  final DateTime asOf;

  const MarketLiquiditySnapshot({
    required this.symbol,
    required this.bidAskSpread,
    required this.volume,
    required this.openInterest,
    required this.slippageEstimate,
    required this.asOf,
  });
}
```

### 3.4 MarketRegimeSnapshot

```dart
class MarketRegimeSnapshot {
  final String symbol;
  final String trend;          // "uptrend", "downtrend", "sideways"
  final String volatility;     // "low", "normal", "high"
  final String liquidity;      // "thin", "normal", "deep"
  final DateTime asOf;

  const MarketRegimeSnapshot({
    required this.symbol,
    required this.trend,
    required this.volatility,
    required this.liquidity,
    required this.asOf,
  });
}
```

## 4. MarketDataService

### 4.1 Responsibilities

- Fetch raw data from provider(s)
- Normalize into snapshots
- Cache per symbol
- Provide **read‑only** APIs:

```dart
abstract class MarketDataService {
  Future<MarketPriceSnapshot> getPrice(String symbol);
  Future<MarketVolatilitySnapshot> getVolatility(String symbol);
  Future<MarketLiquiditySnapshot> getLiquidity(String symbol);
  Future<MarketRegimeSnapshot> getRegime(String symbol);
}
```

Concrete implementation: `LiveMarketDataService` (Phase 6.2+).
Test implementation: `MockMarketDataService`.

## 5. Caching strategy

### 5.1 Per symbol, per category

- Price: cache TTL ~ 5–15 seconds
- Volatility: cache TTL ~ 60–300 seconds
- Liquidity: cache TTL ~ 60–300 seconds
- Regime: cache TTL ~ 300–900 seconds

### 5.2 In‑memory cache

Simple map:

```dart
class _CacheEntry<T> {
  final T value;
  final DateTime asOf;
  const _CacheEntry(this.value, this.asOf);
}
```

`Map<String, _CacheEntry<MarketPriceSnapshot>> _priceCache;` etc.

## 6. Integration points

### 6.1 Regime engine

Consumes:

- `MarketPriceSnapshot`
- `MarketVolatilitySnapshot`
- `MarketLiquiditySnapshot`

Produces:

- `MarketRegimeSnapshot` (or uses it directly if computed in service)

### 6.2 Planner hints

Consumes:

- `MarketRegimeSnapshot`
- `MarketVolatilitySnapshot`
- `MarketLiquiditySnapshot`

Uses them to:

- Adjust recommended ranges
- Show warnings (high IV, thin liquidity, etc.)

### 6.3 Recommendations engine

Consumes:

- `MarketRegimeSnapshot`
- `MarketVolatilitySnapshot`

Uses them to:

- Tighten/loosen risk suggestions
- Adjust parameter recommendations

### 6.4 Narrative engine

Consumes:

- `MarketRegimeSnapshot`
- `MarketVolatilitySnapshot`

Uses them to:

- Add “current conditions” context to the story.

## 7. Call pattern

### 7.1 On cockpit load

For each strategy’s primary symbol:

1. `getPrice(symbol)`
2. `getVolatility(symbol)`
3. `getLiquidity(symbol)`
4. `getRegime(symbol)`

Then:

- Update RegimeEngine
- Update Recommendations
- Update Narrative

### 7.2 On planner open

Same as above, but scoped to the symbol being planned.

## 8. Error handling

- If provider fails → return last cached snapshot if not too stale.
- If no cache → return a **degraded snapshot** with flags (e.g. `trend: "unknown"`).
- Downstream engines must handle “unknown” gracefully (no panic, just softer hints).

## 9. Completion criteria

Phase 6.1 is complete when:

- Core snapshot models exist
- MarketDataService interface is defined
- Caching strategy is defined
- Integration points are clear
- Regime/Planner/Recommendations/Narrative all depend on **MarketDataService**, not raw APIs

After this, Phase 6.2–6.5 are just **plugging real data into a clean socket**.

If you want next, we can:

- Design **Phase 6.2 — Live Regime Engine** on top of these snapshots, or
- Sketch the **Live Planner Hint rules** that react to IV, spread, and trend.
