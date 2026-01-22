# Phase 6.1 — Market Data Architecture

## Purpose
Define the architecture and contracts for ingesting and exposing live market data to the Strategy Intelligence System. This component standardizes feeds (price, volatility, liquidity, regime signals) so downstream engines (Regime, Planner Hints, Recommendations, Narrative) can consume deterministic, testable snapshots.

## Goals
- Provide a consistent, pull‑based API for on‑demand live data retrieval.
- Normalize and enrich raw feeds (candles, IV, OI, spreads) into typed domain objects.
- Offer test doubles and replay modes for deterministic local testing.
- Expose minimal surface area: `MarketDataService` + typed DTOs.

## Core Concepts
- MarketDataService (interface): pull-based queries per symbol and timeframe.
- MarketSnapshot: canonical container for price, vol, liquidity, and derived indicators.
- FeedAdapters: adapters for exchanges/market data vendors (REST/websocket wrappers).
- ReplayProvider: test harness that replays historical ticks/candles for deterministic testing.

## API (sketch)
- MarketDataService
  - Future<MarketSnapshot> fetchSnapshot(Symbol sym, {List<Resolution> resolutions, DateTime? asOf})
  - Stream<MarketSnapshot> subscribe(Symbol sym, {Resolution resolution})
  - Future<void> warmCache(Symbol symbolList[])

- MarketSnapshot
  - latestPrice: double
  - candles: Map<Resolution, List<Candle>>
  - iv: double
  - ivRank: double
  - vix: double?
  - bid: double
  - ask: double
  - spreadPct: double
  - volume: int
  - openInterest: int
  - derivedIndicators: Map<String, double>

## Integration Patterns
- Engines request snapshots on view open or planner interaction (pull‑based) to avoid churn.
- Short‑lived subscriptions used only when UI requires streaming updates; otherwise use single snapshot.
- Use adapters for vendor-specific transforms; keep `MarketDataService` vendor-agnostic.

## Reliability & Determinism
- All fetches should support `asOf` param for deterministic tests.
- Provide a `ReplayProvider` for deterministic playback in tests and offline demos.

## Security & Rate Limits
- Centralize rate‑limit handling in FeedAdapters.
- Cache and backoff on transient errors.

## Completion Criteria
- `MarketDataService` interface added under `lib/services`.
- `MarketSnapshot` DTO defined under `lib/services/market_data_models.dart`.
- At least one `FeedAdapter` scaffolded (e.g., `PolygonAdapter` or `MockAdapter`).
- Replay provider exists for local deterministic runs.
