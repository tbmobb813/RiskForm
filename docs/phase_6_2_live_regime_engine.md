# Phase 6.2 — Live Regime Engine

## Purpose
Turn live market snapshots into real‑time regime signals (trend, volatility, breadth) that the intelligence loop consumes. The Regime Engine produces deterministic regime labels and transition events for downstream engines.

## Responsibilities
- Consume `MarketSnapshot` and compute:
  - Trend classification (bullish / neutral / bearish)
  - Volatility regime (low / medium / high)
  - Breadth & momentum signals
  - Change‑point detection (regime transition events)
- Expose regime descriptors with timestamps and confidence scores.
- Provide time‑series of recent regime states for backtest alignment.

## API (sketch)
- RegimeEngine
  - Future<RegimeState> computeForSnapshot(MarketSnapshot snap)
  - Stream<RegimeState> subscribe(Symbol sym) // optional, for UI streaming

- RegimeState
  - symbol: Symbol
  - trend: TrendLabel {Bull, Neutral, Bear}
  - volatility: VolLabel {Low, Med, High}
  - confidence: double (0..1)
  - dominantIndicators: Map<String,double>
  - timestamp: DateTime

## Algorithms & Heuristics
- Trend: slope of short vs long moving averages, ADX threshold, price vs MA bands.
- Volatility: ATR bands, IV rank thresholds, realized vs implied divergence.
- Transition detection: run a light-weight change-point detector (rolling z-score + hysteresis) to avoid flapping.

## Determinism & Testability
- Regime computation must be stateless and pure for a given input snapshot.
- Expose a `computeForSnapshot` unit API that is fully testable with recorded snapshots.

## Integration
- On snapshot fetch, Planner/Recommendations call `RegimeEngine.computeForSnapshot`.
- RegimeState feeds Recommendation scoring and Planner hint selection.

## Completion Criteria
- `RegimeEngine` interface and `RegimeState` DTO saved in `lib/engines/regime_engine.dart`.
- At least one deterministic trend/volatility heuristic implemented and unit tested.
- Integration example: Planner obtains RegimeState for symbol on open.
