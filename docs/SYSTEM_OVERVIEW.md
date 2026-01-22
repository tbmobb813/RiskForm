# SYSTEM OVERVIEW DOCUMENT
## A Unified Architecture for a Real-Time, Self-Improving Trading Intelligence System

This document gives new engineers, collaborators, or investors a bird's-eye view of the entire system — from strategy lifecycle to live market intelligence — and explains how each subsystem fits into the larger architecture.

## Purpose

This document answers:

- What does the system do
- How does it work
- Why is it designed this way
- How the components interact
- Where it’s going next

## High-Level Vision

This platform is a real-time, self-improving trading intelligence system. It is a behavioral operating system for traders: guiding planning, validating execution, tracking cycles, scoring discipline, analyzing performance, learning from backtests, understanding market regimes, generating recommendations, producing narratives, and adapting to live market conditions.

## Core Loop

Plan → Execute → Cycle → Health → Backtests → Recommendations → Narrative → Plan

## Phase 5 — Strategy Intelligence System

Phase 5 built the intelligence stack: strategy lifecycle engine, health engine, backtest engine, planner, batch backtesting, health scoring, recommendations, regime-aware planner hints, and a narrative engine.

## Phase 6 — Live Market Intelligence Layer

Phase 6 brings real-time market context into the intelligence loop with a unified `MarketDataService`, live regime engine, live planner hints, live recommendations, live narrative, and future live risk monitoring.

## Phase 6.7 — System Synchronization Layer

### Purpose

Phase 6.7 introduces a synchronization layer that ensures:

- All engines receive fresh market data
- All intelligence modules update in the correct order
- UI modules refresh only when needed
- No redundant API calls
- No stale regime or volatility context

### What It Does

- Pulls live market data
- Updates the Live Regime Engine
- Updates Recommendations
- Updates Planner Hints
- Updates Narrative
- Updates Cockpit panels
- Ensures consistent timestamps and deterministic ordering

### Architecture (conceptual)

```
MarketDataService.refresh(symbol)
      |
      ▼
LiveRegimeEngine.update(symbol)
      |
      ▼
StrategyRecommendationsEngine.generate(...)
      |
      ▼
RegimeAwarePlannerHintsService.generate(...)
      |
      ▼
StrategyNarrativeEngine.generate(...)
      |
      ▼
Cockpit + Planner UI update
```

### Synchronization Manager (implementation sketch)

```dart
class LiveSyncManager {
  final MarketDataService market;
  final RegimeEngine regime;
  final StrategyRecommendationsEngine recs;
  final RegimeAwarePlannerHintsService hints;
  final StrategyNarrativeEngine narrative;

  Future<LiveSyncResult> refresh(String symbol, StrategyContext ctx) async {
    final price = await market.getPrice(symbol);
    final vol = await market.getVolatility(symbol);
    final liq = await market.getLiquidity(symbol);

    final reg = await regime.getRegime(symbol);

    final recBundle = await recs.generate(
      context: ctx,
      regime: reg,
      vol: vol,
      liq: liq,
    );

    final hintBundle = hints.generateHints(
      plannerState: ctx.plannerState,
      context: ctx,
      regime: reg,
      vol: vol,
      liq: liq,
    );

    final story = narrative.generate(
      context: ctx,
      recs: recBundle,
      regime: reg,
      vol: vol,
      liq: liq,
    );

    return LiveSyncResult(
      regime: reg,
      recommendations: recBundle,
      hints: hintBundle,
      narrative: story,
    );
  }
}
```

### Completion Criteria

Phase 6.7 is complete when:

- A single `LiveSyncManager` orchestrates live updates
- Cockpit and Planner consume `LiveSyncResult`
- No module fetches market data directly
- Engines update in deterministic order
- UI updates are smooth and synchronized

### Next Steps

- Remove ad-hoc market-data calls across modules
- Wire `LiveSyncManager` into viewmodels (e.g., `StrategyCockpitViewModel`)
- Add end-to-end integration tests for live flows

---

This document should live at `/docs/SYSTEM_OVERVIEW.md` and serve as the canonical onboarding reference for engineers and stakeholders.
