# PHASE 5.6 — Strategy Health Score  
### Production Specification — Final Version

---

## 1. Purpose

Phase 5.6 introduces a **single, opinionated Strategy Health Score** that summarizes:

- Performance quality  
- Discipline quality  
- Regime alignment  
- Consistency  

into a **0–100 score** that:

- Sits at the top of the Strategy Cockpit  
- Trends over time  
- Drives simple, actionable language (“Stable”, “Fragile”, “At Risk”)

This is the “at a glance” signal for whether a strategy is behaving as designed.

---

## 2. High‑Level Concept

Health Score is computed **per StrategyHealthSnapshot** using:

- Recent PnL behavior (trend + drawdown)  
- Recent discipline behavior (trend + level)  
- Regime alignment (how well the strategy fits its regimes)  
- Consistency (variance of cycle outcomes)  

All inputs are already available from:

- `StrategyHealthSnapshot`  
- `StrategyCycle` + analyzers  

No new Firestore collections are required.

---

## 3. Data Model Changes

### 3.1 StrategyHealthSnapshot (extension)

Add:

```dart
final double healthScore;        // 0–100
final List<double> healthTrend;  // optional, last N scores
final String healthLabel;        // "Stable", "Fragile", "At Risk"
```

Persisted in Firestore:

```json
{
  "healthScore": 78.5,
  "healthTrend": [65, 70, 74, 78],
  "healthLabel": "Stable"
}
```

---

## 4. Health Score Formula

Health Score is a **weighted composite** of four sub‑scores:

- Performance Score \(P\)  
- Discipline Score \(D\)  
- Regime Score \(R\)  
- Consistency Score \(C\)  

Final:

\[
Health = 0.35P + 0.35D + 0.20R + 0.10C
\]

All sub‑scores are normalized to \([0, 100]\).

---

## 5. Sub‑Scores

### 5.1 Performance Score \(P\)

Inputs:

- `pnlTrend` (from `StrategyHealthSnapshot`)  
- Recent drawdown (derived from `pnlTrend`)  

Steps:

1. Compute last N (e.g., 5) cycle PnL values.  
2. Compute average PnL and max drawdown over that window.  
3. Map:

   - Positive average PnL → higher score  
   - Large drawdown → penalty  

Example mapping:

- Base = clamp(averagePnLScaled, 0–100)  
- Penalty = min(drawdownScaled, 30)  
- \(P = max(0, Base - Penalty)\)

---

### 5.2 Discipline Score \(D\)

Inputs:

- `disciplineTrend` (from `StrategyHealthSnapshot`)  

Steps:

1. Take last N discipline scores.  
2. Compute:

   - `currentDiscipline = last`  
   - `trendSlope` (simple difference between last and first)  

Mapping:

- Start from `currentDiscipline` (0–100).  
- If trend is negative, subtract up to 15 points.  
- If trend is positive, add up to 10 points (capped at 100).

---

### 5.3 Regime Score \(R\)

Inputs:

- `regimePerformance` (from `StrategyHealthSnapshot`)  
- `currentRegime`  

Steps:

1. For `currentRegime`, read:

   - `pnl`  
   - `winRate`  
   - `avgDiscipline`  

2. Map:

   - Positive pnl + decent winRate → higher score  
   - Negative pnl → penalty  

If `currentRegime` is null or unknown, fall back to average across all regimes.

---

### 5.4 Consistency Score \(C\)

Inputs:

- `pnlTrend`  

Steps:

1. Take last N PnL values.  
2. Compute standard deviation.  
3. Map:

   - Lower variance → higher consistency score  
   - Higher variance → lower score  

Example:

- Normalize stdDev into 0–100, then invert:

\[
C = 100 - normalizedStdDev
\]

---

## 6. Health Label

Based on final Health Score:

- **80–100** → `"Stable"`  
- **60–79** → `"Fragile"`  
- **0–59** → `"At Risk"`  

This label is stored as `healthLabel` and used in the cockpit header.

---

## 7. Implementation: StrategyHealthService

Extend `_computeSnapshot` to:

1. Compute sub‑scores \(P, D, R, C\) from existing snapshot inputs.  
2. Compute final `healthScore`.  
3. Append `healthScore`, `healthLabel`, and updated `healthTrend`.

Pseudo‑Dart inside `_computeSnapshot`:

```dart
final performanceScore = _computePerformanceScore(pnlTrend);
final disciplineScore = _computeDisciplineScore(disciplineTrend);
final regimeScore = _computeRegimeScore(regimePerformance, currentRegime);
final consistencyScore = _computeConsistencyScore(pnlTrend);

final healthScore =
    0.35 * performanceScore +
    0.35 * disciplineScore +
    0.20 * regimeScore +
    0.10 * consistencyScore;

final healthLabel = healthScore >= 80
    ? 'Stable'
    : healthScore >= 60
        ? 'Fragile'
        : 'At Risk';

final newHealthTrend = [...(existingHealthTrend ?? []), healthScore]
    .takeLast(20); // keep last 20
```

Then include these fields in `StrategyHealthSnapshot`.

---

## 8. Cockpit UI Integration

### 8.1 Header

Add:

- **Health Score badge** (e.g., “Health: 78 — Stable”)  
- Color accent:

  - Stable → soft green  
  - Fragile → amber  
  - At Risk → muted red  

### 8.2 Health Trend Mini‑Chart (optional)

Small sparkline using `healthTrend`:

- X: last N snapshots  
- Y: healthScore  

### 8.3 Drill‑Down

Hover / tap reveals:

- Performance Score  
- Discipline Score  
- Regime Score  
- Consistency Score  

So the user can see *why* the health is what it is.

---

## 9. End‑to‑End Flow

1. Executions update cycles.  
2. Cycles update StrategyHealthSnapshot.  
3. StrategyHealthService computes Health Score.  
4. Snapshot written with `healthScore`, `healthLabel`, `healthTrend`.  
5. Cockpit header + modules update.  

The user now has a **single, disciplined signal** for strategy condition.

---

## 10. Completion Criteria

Phase 5.6 is complete when:

- `healthScore`, `healthLabel`, and `healthTrend` are computed and stored for each snapshot.  
- Cockpit header displays Health Score + label.  
- Health Score responds to changes in performance, discipline, and regime alignment.  
- No manual intervention is required; the pipeline is fully automatic.  

---

If you want next, we can:

- Turn this into **concrete Dart code** inside `StrategyHealthService`, or  
- Design the **Health Score header UI** with exact widgets and states.
