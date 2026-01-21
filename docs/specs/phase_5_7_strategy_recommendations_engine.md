# **PHASE 5.7 — Strategy Recommendations Engine**
### *Production Specification — Final Version*

---

## 🎯 **1. Purpose**

Phase 5.7 introduces a **Strategy Recommendations Engine** that transforms raw analytics into **clear, actionable, context‑aware guidance**.

This engine produces:

- Parameter recommendations (DTE, delta, width)  
- Risk adjustments (size, frequency, exposure)  
- Discipline nudges (slippage, over‑adjustment, revenge trading)  
- Regime‑aware hints (trend alignment, volatility sensitivity)  
- Backtest‑driven suggestions (best configs, weak configs)  
- Cycle‑based behavioral insights  

These recommendations appear in:

- The **Strategy Cockpit** (Recommendations Panel)  
- The **Planner** (inline hints + warnings)  
- The **Execution flow** (pre‑trade checks)  

This is where your platform becomes a **coach**, not just a dashboard.

---

## 🧠 **2. High‑Level Architecture**

```
StrategyHealthSnapshot
StrategyCycle (last N)
BacktestComparisonResult
RegimeContext
DisciplineSignals
Constraints
      │
      ▼
StrategyRecommendationsEngine
      │
      ├── Cockpit Recommendations Panel
      ├── Planner Hints
      └── Execution Warnings
```

The engine is **pure**, **deterministic**, and **side‑effect free**.

---

## 📦 **3. Data Inputs**

The engine consumes:

### **3.1 StrategyHealthSnapshot**
- pnlTrend  
- disciplineTrend  
- regimePerformance  
- regimeWeaknesses  
- healthScore  
- healthLabel  

### **3.2 Recent Cycles**
- last 3–5 cycles  
- cycle disciplineScore  
- cycle pnl  
- cycle regime  

### **3.3 Backtest Comparison**
- bestConfig  
- weakConfig  
- regimeWeaknesses  
- summaryNote  

### **3.4 Strategy Constraints**
- maxRisk  
- maxPositions  
- allowedDteRange  
- allowedDeltaRange  

### **3.5 Regime Context**
- currentRegime  
- volatility regime (optional future)  

---

## 🧩 **4. Recommendation Types**

The engine produces **five categories** of recommendations:

### **4.1 Parameter Recommendations**
Derived from:

- Backtest bestConfig  
- Regime alignment  
- Recent cycle performance  

Examples:

- “Based on recent performance, consider tightening delta to 0.15–0.20.”  
- “Your best backtests cluster around DTE 25–35.”  

---

### **4.2 Risk Recommendations**
Derived from:

- Drawdown  
- Health Score  
- Discipline trend  

Examples:

- “Your discipline trend is slipping; reduce size by 20% until stability returns.”  
- “Recent losses suggest reducing frequency to 1–2 trades per cycle.”  

---

### **4.3 Regime Recommendations**
Derived from:

- currentRegime  
- regimePerformance  
- regimeWeaknesses  

Examples:

- “Strategy underperforms in downtrend; consider defensive adjustments.”  
- “Sideways regime favors neutral income structures.”  

---

### **4.4 Discipline Recommendations**
Derived from:

- disciplineTrend  
- cycle disciplineScore  
- execution patterns  

Examples:

- “You’ve adjusted too frequently in the last 3 cycles.”  
- “Your last cycle shows over‑sizing relative to constraints.”  

---

### **4.5 Consistency Recommendations**
Derived from:

- pnlTrend variance  
- cycle variance  

Examples:

- “Your PnL variance is high; consider narrowing width.”  
- “Cycle outcomes are inconsistent; tighten entry criteria.”  

---

## 🧮 **5. Recommendation Engine Logic**

The engine is a pure function:

```
StrategyRecommendations generate(StrategyContext ctx)
```

Where `ctx` includes:

- healthSnapshot  
- recentCycles  
- backtestComparison  
- constraints  
- regimeContext  

The engine evaluates **rules** grouped by category.

---

## ⚙️ **6. Rule System**

The engine uses a **deterministic rule stack**:

### **6.1 Parameter Rules**

```
IF bestConfig exists
  recommend bestConfig ranges

IF regimeWeaknesses include currentRegime
  recommend adjusting delta or width

IF pnlTrend shows 3 consecutive losses
  recommend reducing delta or DTE
```

---

### **6.2 Risk Rules**

```
IF healthScore < 60
  recommend reducing size by 20–40%

IF drawdown > threshold
  recommend reducing frequency

IF disciplineTrend is negative
  recommend smaller positions
```

---

### **6.3 Regime Rules**

```
IF currentRegime == "uptrend"
  recommend premium selling in strength

IF currentRegime == "downtrend"
  recommend defensive structures

IF currentRegime == "sideways"
  recommend neutral income strategies
```

---

### **6.4 Discipline Rules**

```
IF disciplineTrend.last < 60
  recommend slowing down

IF cycle disciplineScore dropped > 10 points
  recommend reviewing journal notes

IF over-adjustment detected
  recommend fewer intracycle changes
```

---

### **6.5 Consistency Rules**

```
IF pnl variance high
  recommend narrowing width

IF cycle outcomes inconsistent
  recommend reducing delta range
```

---

## 🏗 **7. Output Model**

`StrategyRecommendation`:

```dart
class StrategyRecommendation {
  final String category;   // "risk", "parameter", "regime", "discipline", "consistency"
  final String message;    // human-readable recommendation
  final int priority;      // 1–5
}
```

`StrategyRecommendationsBundle`:

```dart
class StrategyRecommendationsBundle {
  final List<StrategyRecommendation> recommendations;
  final DateTime generatedAt;
}
```

---

## 🖥 **8. Cockpit UI Integration**

### **8.1 Recommendations Panel**

Displays:

- Top 3 recommendations  
- Category icons  
- Priority indicators  
- Expandable list for full details  

### **8.2 Planner Integration**

Inline hints:

- Under DTE slider  
- Under delta slider  
- Under width slider  
- Under size input  

Warnings:

- “This trade violates your recommended delta range.”  
- “Your discipline trend suggests reducing size.”  

### **8.3 Execution Integration**

Pre‑trade checks:

- “This trade conflicts with your best backtest configuration.”  
- “Your health score is fragile; consider reducing size.”  

---

## 🔄 **9. End‑to‑End Flow**

1. Execution updates cycle  
2. Cycle updates health snapshot  
3. Health snapshot triggers recommendation engine  
4. Recommendations written to Firestore  
5. Cockpit + Planner update automatically  

This completes the **Strategy Intelligence Loop**:

**Analyze → Recommend → Execute → Learn → Improve**

---

## ✅ **10. Completion Criteria**

Phase 5.7 is complete when:

- Recommendation engine produces deterministic outputs  
- Recommendations appear in Cockpit  
- Planner shows inline hints  
- Execution shows warnings  
- Recommendations update after each cycle  
- No manual refresh required  

---

## 🚀 **11. What’s Next**

You’re now ready for:

### **Phase 5.8 — Regime‑Aware Planner Hints**  
Inject recommendations directly into the Planner UI in real time.

Or:

### **Phase 6 — Live Market Data Integration**  
Feed real‑time regime + volatility context into the entire engine.

Just tell me which direction you want to push next.
