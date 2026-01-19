# Backtest Engine Specification

The Backtest Engine simulates the Wheel lifecycle over historical data.

---

# Inputs
- `BacktestConfig`
- Historical OHLC data
- Regime segments

---

# Outputs
- `BacktestResult`
- `CycleStats[]`
- Equity curve
- Drawdown curve
- Regime analytics
- Journal entries

---

# Core Logic

## 1. CSP Phase
- Select strike using strikeSelectionRule
- Compute premium using pricing engine
- Track daily P/L and theta decay
- On expiration:
  - Assign if price ≤ strike
  - Otherwise expire OTM

## 2. CC Phase
- Select strike based on config
- Compute premium
- Track daily P/L
- On expiration:
  - Called away if price ≥ strike
  - Otherwise expire OTM

---

# Determinism
- No randomness
- No early assignment
- All results reproducible

---

# Versioning
Recommended field:
- `engineVersion: "1.0.0"`
