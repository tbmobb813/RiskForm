# PHASE 5.9 — Strategy Narrative Engine
### *Production Specification — Final Version*

---

# 1. Purpose

Phase 5.9 introduces the **Strategy Narrative Engine**, a deterministic, context‑aware generator that produces a **human‑readable “Strategy Story”** summarizing:

- Recent cycles  
- Health score + trends  
- Regime behavior  
- Discipline signals  
- Backtest insights  
- Recommendations  

This narrative is:

- Short  
- Clear  
- Actionable  
- Emotionally neutral  
- Cockpit‑ready  

It becomes the **top‑level summary** of a strategy’s condition — the thing a user reads before making any decision.

---

# 2. High‑Level Architecture

```
StrategyCycles (last N)
StrategyHealthSnapshot
StrategyRecommendationsBundle
BacktestComparisonResult
RegimeContext
      │
      ▼
StrategyNarrativeEngine
      │
      ├── Cockpit Narrative Panel
      ├── Planner Context Summary
      └── Exportable “Strategy Story”
```

The engine is **pure**, **stateless**, and **fully deterministic**.

---

# 3. Inputs

The narrative engine consumes:

### 3.1 Recent Cycles
- pnl  
- disciplineScore  
- regime  
- adjustments  
- outcomes  

### 3.2 StrategyHealthSnapshot
- healthScore  
- healthLabel  
- pnlTrend  
- disciplineTrend  
- regimePerformance  
- regimeWeaknesses  

### 3.3 Recommendations (Phase 5.7)
- parameter  
- risk  
- regime  
- discipline  
- consistency  

### 3.4 Backtest Comparison
- bestConfig  
- weakConfig  
- regimeWeaknesses  
- summaryNote  

### 3.5 Regime Context
- currentRegime  
- volatility regime (future)  

---

# 4. Output Model

`StrategyNarrative`:

```dart
class StrategyNarrative {
  final String title;        // e.g. Current Strategy Story
  final String summary;      // 2–3 sentence overview
  final List<String> bullets; // key insights
  final String outlook;      // forward-looking guidance
  final DateTime generatedAt;
}
```

This is the **canonical narrative envelope**.

---

# 5. Narrative Structure

The narrative has **four sections**:

---

## 5.1 Overview (2–3 sentences)
Summarizes:

- Recent cycle behavior  
- Health condition  
- Regime context  

Example:

> “Over the last three cycles, the strategy has shown stable performance with improving discipline. Current market conditions are sideways, where this strategy historically performs well. Overall health is stable, supported by consistent execution.”

---

## 5.2 Key Insights (bullets)
Derived from:

- cycle outcomes  
- discipline changes  
- regime performance  
- backtest insights  

Examples:

- “Recent cycles show positive PnL with reduced variance.”  
- “Discipline trend improved from 62 → 74.”  
- “Strategy underperforms in downtrend regimes.”  
- “Best backtests cluster around DTE 25–35 and delta 0.15–0.20.”  

---

## 5.3 Backtest & Regime Interpretation
Explains:

- how backtests relate to current regime  
- whether current inputs align with best configs  
- whether regime weaknesses matter now  

Example:

> “Backtest results indicate strong performance in sideways regimes, which aligns with current market conditions. Weak configurations appear when delta exceeds 0.30, suggesting caution with aggressive entries.”

---

## 5.4 Forward‑Looking Outlook
Synthesizes:

- recommendations  
- health score  
- regime context  
- discipline signals  

Example:

> “Given the current regime and recent performance, the strategy is positioned well. Consider maintaining delta between 0.15–0.20 and reducing size slightly to reinforce discipline. Expect stable behavior if market conditions remain neutral.”

---

# 6. Narrative Engine Logic

The engine is a pure function:

```
StrategyNarrative generateNarrative(StrategyContext ctx)
```

Where `ctx` includes:

- cycles  
- healthSnapshot  
- recommendations  
- backtestComparison  
- regimeContext  

---

## 6.1 Overview Rules

```
IF healthLabel == "Stable"
  use positive-neutral tone

IF healthLabel == "Fragile"
  use cautious tone

IF healthLabel == "At Risk"
  use defensive tone
```

Regime mapping:

```
uptrend → “strength”
downtrend → “pressure”
sideways → “neutral conditions”
```

---

## 6.2 Key Insight Rules

Include bullets for:

- cycle PnL trend  
- discipline trend  
- regime performance  
- backtest best/weak configs  
- healthScore changes  

---

## 6.3 Backtest Interpretation Rules

```
IF currentRegime matches bestConfig regime
  highlight alignment

IF weakConfig conflicts with current inputs
  warn gently

IF regimeWeaknesses include currentRegime
  highlight risk
```

---

## 6.4 Outlook Rules

Combine:

- top 1–2 recommendations  
- regime guidance  
- discipline nudges  
- risk adjustments  

Tone:

- Stable → confident  
- Fragile → cautious  
- At Risk → defensive  

---

# 7. UI Integration

### 7.1 Cockpit Narrative Panel

Placed at the top of the Strategy Cockpit:

- Title: “Strategy Story”  
- Summary paragraph  
- Bullet insights  
- Outlook paragraph  

### 7.2 Planner Context Summary

Displayed when Planner opens:

- “Here’s what your strategy has been doing recently…”  
- Shortened version of the narrative  

### 7.3 Exportable Narrative

User can copy/paste the narrative for journaling.

---

# 8. Example Narrative (Generated)

Here’s what the engine would produce for a typical strategy:

---

### **Strategy Story — January 2026**

Over the last three cycles, the strategy has delivered steady gains with improving discipline. Current market conditions are sideways, a regime where this strategy historically performs well. Overall health is stable and trending upward.

**Key Insights**
- Recent cycles show consistent positive PnL with reduced variance.  
- Discipline improved from 62 → 74 over the last three cycles.  
- Backtests highlight strong performance with DTE 25–35 and delta 0.15–0.20.  
- Strategy tends to underperform in downtrend regimes.  

**Backtest & Regime Interpretation**  
Backtest results align well with the current sideways regime. Weak configurations appear when delta exceeds 0.30, suggesting caution with aggressive entries. Current cycle behavior matches the best‑performing backtest clusters.

**Outlook**  
Maintain delta between 0.15–0.20 and keep width moderate to reinforce consistency. With discipline improving and regime alignment favorable, the strategy is positioned for stable performance if conditions remain neutral.

---

# 9. Completion Criteria

Phase 5.9 is complete when:

- Narrative engine produces deterministic, human‑readable stories  
- Cockpit displays narrative panel  
- Planner shows shortened narrative  
- Narrative updates after each cycle  
- Narrative incorporates health, regime, backtests, and recommendations  
- No manual refresh required  

---

# 10. What’s Next

You’re now ready for:

### Phase 6 — Live Market Data Integration  
Feed real‑time volatility, trend, and liquidity context into:

- Regime engine  
- Planner hints  
- Recommendations  
- Narrative engine  

Or, if you want to close out Phase 5:

### Phase 5 Master Document  
A unified spec summarizing 5.1–5.9 as a single intelligence system.
