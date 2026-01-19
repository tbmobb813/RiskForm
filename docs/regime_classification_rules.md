# Regime Classification Rules

Regimes classify market behavior into:
- Uptrend
- Downtrend
- Sideways

---

# Inputs
- Historical OHLC data
- Lookback window (default: 10 days)
- Uptrend threshold: +3%
- Downtrend threshold: –3%

---

# Algorithm
1. Compute rolling return over lookback window.
2. If return ≥ +3% → uptrend.
3. If return ≤ –3% → downtrend.
4. Else → sideways.
5. Merge consecutive segments of same regime.
6. Map cycles to regimes by date overlap.

---

# RegimeSegment
- `regime`
- `startDate`
- `endDate`
- `startIndex`
- `endIndex`
