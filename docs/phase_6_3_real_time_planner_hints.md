# Phase 6.3 — Real‑Time Planner Hints

## Purpose
Make the Planner UI and execution logic responsive to live market conditions by injecting real‑time hints, warnings, and recommended parameter ranges derived from live snapshots and regime signals.

## Key Outputs
- Recommended delta, width, DTE (with confidence)
- Liquidity warnings (bid/ask, spreadPct)
- Volatility nudges (widen width, reduce size)
- Regime‑aligned suggestions (conservative/aggressive)

## API (sketch)
- PlannerHintsService
  - Future<PlannerHintsBundle> generateHints(PlannerInputs inputs, MarketSnapshot snap, RegimeState regime)

- PlannerHintsBundle
  - recommendedRanges: Map<String, Range>
  - bestPoints: Map<String, double>
  - weakRanges: Map<String, Range>
  - warnings: List<PlannerWarning>
  - confidence: double

- PlannerWarning
  - code: String
  - message: String
  - severity: {Info, Warning, Critical}

## Heuristics
- IV Rank high -> suggest wider width or higher DTE
- SpreadPct > threshold -> emit Liquidity warning and recommend smaller size
- Trend weakening -> reduce recommended delta magnitude
- Low volume / thin OI -> advise conservative sizing

## UI Integration
- Planner calls `generateHints` on snapshot fetch or when inputs change.
- Hints update overlays, legends, and textual warnings in the Planner.
- Hints are cached short‑term (e.g., 30s) and invalidated on new snapshot.

## Determinism
- `generateHints` must be pure given `inputs`, `snapshot`, and `regime` to allow unit testing.

## Completion Criteria
- `PlannerHintsService` interface added to `lib/services/planner_hints_service.dart`.
- `PlannerHintsBundle` DTO added and used by Planner UI.
- Unit tests that validate at least 3 heuristic rules (IV rank, spread, trend). 
