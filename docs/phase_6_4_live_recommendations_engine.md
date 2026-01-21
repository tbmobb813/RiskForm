# Phase 6.4 — Live Recommendations Engine

## Purpose
Adapt the Strategy Recommendations Engine to incorporate live market context so recommendations reflect both historical backtests and current market conditions.

## Responsibilities
- Re-score recommendation priorities with live-adjusted risk and regime multipliers.
- Produce actionable items: parameter changes, sizing recommendations, regime-specific tactics.
- Expose confidence and provenance (backtest vs live signal weighting).

## API (sketch)
- LiveRecommendationsEngine
  - Future<StrategyRecommendationsBundle> generate(MetaContext ctx, MarketSnapshot snap, RegimeState regime)

- StrategyRecommendationsBundle
  - recommendations: List<Recommendation>
  - healthImpact: Map<String,double>
  - confidence: double
  - provenance: {backtestWeight: double, liveWeight: double}

- Recommendation
  - id: String
  - category: {Parameter, Risk, Regime, Discipline}
  - title: String
  - description: String
  - impactScore: double
  - suggestedChange: Map<String, dynamic> // e.g. {"width": 1.5}

## Scoring Model
- Start with backtest-driven recommendation scores.
- Apply live modifiers from RegimeState, IV/Spread signals, and liquidity indicators.
- Interpolate a final score: final = alpha * backtestScore + (1-alpha) * liveScore (alpha configurable).

## Safety
- Recommendations that imply risk increases must include mitigations (size limits, stop suggestions).
- Provide a `previewImpact(plan)` API to simulate healthScore delta if user applies recommendations.

## Integration
- Cockpit requests live recommendations when user opens strategy view or when market signals change materially.
- Planner may request targeted recommendations for a specific input space (e.g., width sweep).

## Completion Criteria
- `LiveRecommendationsEngine` scaffolded under `lib/engines/live_recommendations_engine.dart`.
- Provenance fields added to existing `StrategyRecommendationsBundle` DTO.
- Unit tests showing live-modifier changes to output confidence and ordering.
