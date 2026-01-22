# PHASE 6.3 — Live Planner Hints
### Real‑Time Regime‑Aware Guidance in the Planner

## 1. Purpose

Phase 6.3 wires the **Live Regime Engine** (Phase 6.2) directly into the Planner so that the moment a user selects a symbol or adjusts a parameter, the Planner responds with:

- Live trend‑aware hints
- Live volatility‑aware warnings
- Live liquidity‑aware cautions
- Backtest alignment hints
- Discipline‑aware nudges
- Constraint‑aware warnings
- Recommended ranges based on live conditions

This turns the Planner into a **dynamic, adaptive decision assistant**.

## 2. High‑Level Architecture

```
LiveMarketDataService
      │
      ▼
LiveRegimeEngine
      │
      ▼
RegimeAwarePlannerHintsService (Phase 5.8)
      │
      ▼
Planner UI (real-time hints + warnings)
```

Phase 6.3 simply **feeds live data** into the existing Phase 5.8 hint engine.

## 3. Data Flow

### 3.1 When the Planner opens
1. User selects a symbol
2. Planner loads:
   - MarketPriceSnapshot
   - MarketVolatilitySnapshot
   - MarketLiquiditySnapshot
   - MarketRegimeSnapshot
3. Hints engine generates live hints
4. UI displays them immediately

### 3.2 When the user adjusts inputs
- DTE slider
- Delta slider
- Width slider
- Size input

→ Hints engine recomputes hints using **live regime context**.

## 4. Live Planner Hint Inputs

The hint engine now receives:

### 4.1 Live Regime Snapshot
- `trend`
- `volatility`
- `liquidity`

### 4.2 Market Snapshots
- ATR
- IV Rank
- Spread
- Volume
- Open interest

### 4.3 Strategy Intelligence
- Health score
- Discipline trend
- Backtest best/weak configs
- Recommendations

### 4.4 Planner State
- Current DTE
- Current delta
- Current width
- Current size

## 5. Live Hint Categories

Phase 6.3 adds **three new categories** on top of Phase 5.8:

### 5.1 Trend‑Aware Hints

Uptrend
- “Uptrend detected — tighter deltas favored.”
- “Avoid fading strength; consider DTE 25–35.”

Downtrend
- “Downtrend detected — defensive posture recommended.”
- “Reduce size or widen width to manage downside volatility.”

Sideways
- “Sideways regime — neutral income structures favored.”
- “Delta‑neutral entries perform best in this environment.”

### 5.2 Volatility‑Aware Hints

Based on IV Rank:

High Volatility (IVR ≥ 70)
- “High volatility — widen width or reduce size.”
- “Premium selling favored; avoid narrow spreads.”

Low Volatility (IVR ≤ 30)
- “Low volatility — premium selling less effective.”
- “Consider tighter width or smaller DTE.”

Normal Volatility
- “Volatility normal — standard parameters apply.”

### 5.3 Liquidity‑Aware Hints

Based on spread, volume, open interest:

Thin Liquidity
- “Wide spread — expect slippage.”
- “Avoid complex structures; reduce size.”

Deep Liquidity
- “Deep liquidity — fills should be smooth.”

## 6. Combined Hint Logic

The hint engine now evaluates:

```
LiveRegimeSnapshot
+ MarketVolatilitySnapshot
+ MarketLiquiditySnapshot
+ BacktestComparisonResult
+ StrategyRecommendationsBundle
+ StrategyHealthSnapshot
+ PlannerState
```

And produces a **merged, prioritized hint list**.

## 7. Example Hint Rules

### 7.1 Trend + Delta
```
IF trend == "uptrend" AND delta > 0.25
  show warning: "Aggressive delta in uptrend — consider tightening."
```

### 7.2 Volatility + Width
```
IF volatility == "high" AND width < recommendedWidth
  show warning: "Width too narrow for high volatility."
```

### 7.3 Liquidity + Size
```
IF liquidity == "thin" AND size > 1
  show danger: "Thin liquidity — reduce size to avoid slippage."
```

### 7.4 Backtest + Live Regime
```
IF bestConfig.deltaRange conflicts with current delta
  show info: "Best backtests favor delta 0.15–0.20 in this regime."
```

### 7.5 Discipline + Volatility
```
IF disciplineTrend declining AND volatility == "high"
  show danger: "High volatility + slipping discipline — reduce size."
```

## 8. UI Integration

### 8.1 Inline Hints Under Inputs
- Under DTE slider:
  “Sideways regime — DTE 25–35 performs best.”

- Under delta slider:
  “High volatility — avoid deltas above 0.25.”

- Under width slider:
  “Uptrend — tighter width may reduce variance.”

### 8.2 Warning Banners
- “Thin liquidity — expect slippage.”
- “Delta exceeds recommended range for current regime.”

### 8.3 Recommended Range Overlays
- Shaded region for recommended delta
- Dotted lines for best backtest configs
- Red zones for weak configs

## 9. Performance Considerations

- Market data cached (Phase 6.1)
- Regime classification cheap
- Hints recompute only on:
  - symbol change
  - slider change
  - size change
  - live data refresh

## 10. Completion Criteria

Phase 6.3 is complete when:

- Planner displays live trend/vol/liquidity hints
- Hints update instantly as user adjusts inputs
- Backtest + health + discipline hints merge with live hints
- Recommended ranges overlay on sliders
- Warnings appear for regime/vol/liquidity violations
- No manual refresh required

If you want, next we can design:

### Phase 6.4 — Live Recommendations Engine
(Recommendations adapt to live trend/vol/liquidity)

or

### Phase 6.5 — Live Narrative Engine
(Narrative includes real‑time market conditions)
