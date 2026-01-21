# PHASE 5.8 — Regime‑Aware Planner Hints
### *Production Specification — Final Version*

---

# 1. Purpose

Phase 5.8 injects **real‑time intelligence** into the Planner.

The Planner becomes aware of:

- **Current market regime**  
- **Strategy regime performance**  
- **Strategy recommendations (Phase 5.7)**  
- **Discipline trends**  
- **Constraints**  
- **Backtest best/weak configs**  

And uses this context to provide:

- Inline hints  
- Warnings  
- Nudges  
- Recommended ranges  
- Regime‑specific overlays  

This transforms the Planner from a neutral input form into a **guided execution assistant**.

---

# 2. High‑Level Architecture

```
StrategyHealthSnapshot
StrategyRecommendationsBundle
StrategyConstraints
RegimeContext
      │
      ▼
RegimeAwarePlannerHintsService
      │
      ├── Planner UI (inline hints)
      ├── Planner warnings (violations)
      └── Planner recommended ranges (overlays)
```

The Planner becomes a **contextual UI**, not a static one.

---

# 3. Data Inputs

The hints engine consumes:

### 3.1 StrategyHealthSnapshot
- currentRegime  
- regimePerformance  
- regimeWeaknesses  
- disciplineTrend  
- healthScore  
- healthLabel  

### 3.2 StrategyRecommendationsBundle
- parameter recommendations  
- risk recommendations  
- regime recommendations  
- discipline recommendations  
- consistency recommendations  

### 3.3 Strategy Constraints
- allowedDteRange  
- allowedDeltaRange  
- maxRisk  
- maxPositions  

### 3.4 Backtest Comparison
- bestConfig  
- weakConfig  
- regimeWeaknesses  

---

# 4. Output Model

`PlannerHint`:

```dart
class PlannerHint {
  final String field;     // "dte", "delta", "width", "size", "type"
  final String message;   // human-readable hint
  final String severity;  // "info", "warning", "danger"
}
```

`PlannerHintBundle`:

```dart
class PlannerHintBundle {
  final List<PlannerHint> hints;
  final Map<String, RangeValues> recommendedRanges; // e.g. delta: 0.15–0.20
}
```

---

# 5. Hint Categories

The Planner displays **five types of hints**.

---

## 5.1 Regime‑Based Hints

Derived from:

- `currentRegime`  
- `regimePerformance[currentRegime]`  
- `regimeWeaknesses`  

Examples:

- **Uptrend:**  
  “Uptrend detected — strategy historically performs best with tighter deltas.”

- **Downtrend:**  
  “Downtrend detected — widen width or reduce size for defensive posture.”

- **Sideways:**  
  “Sideways regime — neutral income structures favored.”

---

## 5.2 Backtest‑Driven Hints

Derived from:

- bestConfig  
- weakConfig  
- backtest regime weaknesses  

Examples:

- “Best backtests cluster around DTE 25–35.”  
- “Weak configs show delta > 0.30 — consider tightening.”  
- “Strategy loses in downtrend — avoid aggressive deltas.”

---

## 5.3 Discipline‑Aware Hints

Derived from:

- disciplineTrend  
- cycle disciplineScore  
- healthLabel  

Examples:

- “Discipline trend slipping — reduce size by 20%.”
- “Last cycle shows over‑adjustment — avoid intraday changes.”
- “Health is fragile — consider smaller width.”

---

## 5.4 Constraint‑Aware Hints

Derived from:

- allowedDteRange  
- allowedDeltaRange  
- maxRisk  
- maxPositions  

Examples:

- “Delta 0.35 exceeds your allowed range (0.10–0.30).”  
- “This width produces risk above your maxRisk.”  
- “You already have max positions open.”

---

## 5.5 Consistency‑Based Hints

Derived from:

- pnlTrend variance  
- cycle variance  

Examples:

- “High variance detected — tighten delta range.”
- “Recent cycles inconsistent — consider reducing width.”

---

# 6. Hint Generation Logic

The engine is a pure function:

```
PlannerHintBundle generateHints(PlannerState state, StrategyContext ctx)
```

Where `ctx` includes:

- healthSnapshot  
- recommendations  
- constraints  
- backtestComparison  

---

## 6.1 Regime Rules

```
IF currentRegime == "uptrend"
  recommend tighter delta (0.15–0.20)

IF currentRegime == "downtrend"
  warn if delta > 0.25
  warn if width < recommended defensive width

IF currentRegime == "sideways"
  recommend neutral structures (IC, strangles)
```

---

## 6.2 Backtest Rules

```
IF bestConfig exists
  overlay recommended ranges from bestConfig

IF weakConfig conflicts with user input
  show warning

IF regimeWeaknesses include currentRegime
  show danger hint
```

---

## 6.3 Discipline Rules

```
IF disciplineTrend.last < 60
  warn on large size

IF disciplineTrend trending downward
  show nudge: "reduce size"

IF over-adjustment detected
  warn on frequent adjustments
```

---

## 6.4 Constraint Rules

```
IF user delta outside allowedDeltaRange
  show danger hint

IF user DTE outside allowedDteRange
  show warning

IF risk > maxRisk
  show danger hint
```

---

## 6.5 Consistency Rules

```
IF pnl variance high
  recommend narrower width

IF cycle variance high
  recommend smaller delta range
```

---

# 7. Planner UI Integration

The Planner UI displays hints:

### 7.1 Inline Under Inputs

Under DTE slider:

- “Recommended: 25–35 (based on backtests).”

Under delta slider:

- “Uptrend: tighter deltas favored.”

Under width slider:

- “High variance detected — consider narrowing width.”

Under size input:

- “Discipline trend slipping — reduce size.”

---

### 7.2 Warning Banners

Shown when user violates:

- constraints  
- regime weaknesses  
- weak backtest configs  

Example:

> ⚠️ *Delta 0.35 exceeds recommended range for current regime.*

---

### 7.3 Recommended Range Overlays

Sliders show:

- shaded recommended region  
- dotted lines for bestConfig  
- red zones for weakConfig  

---

# 8. End‑to‑End Flow

1. User opens Planner with `PlannerStrategyContext`.  
2. Planner loads:  
   - StrategyHealthSnapshot  
   - StrategyRecommendationsBundle  
   - BacktestComparisonResult  
   - Constraints  
3. User adjusts inputs.  
4. RegimeAwarePlannerHintsService recomputes hints in real time.  
5. Planner UI updates inline hints + warnings.  
6. ExecutionService still validates final trade.  

This creates a **guided execution experience**.

---

# 9. Completion Criteria

Phase 5.8 is complete when:

- Planner displays regime‑aware hints  
- Backtest‑driven hints appear  
- Discipline‑aware hints appear  
- Constraint violations show warnings  
- Recommended ranges overlay on sliders  
- Hints update in real time as user changes inputs  
- ExecutionService still enforces hard rules  

---

# 10. What’s Next

You’re now ready for:

### Phase 6 — Live Market Data Integration  
Feed real‑time volatility, trend, and liquidity context into:

- Regime engine  
- Planner hints  
- Execution validation  
- Strategy recommendations  

Or, if you want to stay in Phase 5:

### Phase 5.9 — Strategy Narrative Engine  
Generate a human‑readable “Strategy Story” summarizing:

- Recent cycles  
- Health  
- Regime behavior  
- Recommendations  
- Backtest insights  

Just tell me where you want to go.
