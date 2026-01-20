# Phase 5.3 — Strategy Cockpit
_Specification Document_

## 1. Purpose

The Strategy Cockpit is the **central command screen** for each strategy.
It consolidates:

- Lifecycle state
- Performance
- Discipline
- Regime behavior
- Cloud backtests
- Actions (pause, resume, retire)

The cockpit gives the user a calm, cockpit‑like overview of how a strategy is behaving across time, regimes, and discipline dimensions.

This is the primary UX surface for Phase 5.

## 2. Scope

The Strategy Cockpit includes:

- Strategy header (state, tags, constraints)
- Performance module
- Discipline module
- Regime module
- Backtest module
- Lifecycle actions
- Planner integration

Out of scope:

- Editing strategy metadata (covered in Strategy List)
- Running multi‑strategy comparisons (Phase 5.4+)
- Portfolio allocation (future phase)

## 3. Data Dependencies

The cockpit consumes:

- `strategies/{strategyId}`
- `strategyHealth/{strategyId}`
- `strategyEvents/{strategyId}`
- `journalEntries` filtered by `strategyId`
- `positions` filtered by `strategyId`
- `strategyBacktestResults` filtered by `strategyId`
- `RegimeSnapshot` (current regime)

All of these are already defined in Phase 5.1 and 5.2.

## 4. Screen Layout

The Strategy Cockpit is composed of **six modules**, each collapsible and scroll‑friendly.

### 4.1 Header Module — Strategy Identity & State

**Fields:**

- Strategy name
- State badge: Active | Paused | Retired | Experimental
- Tags
- Constraints summary
- Last updated timestamp

**Actions:**

- Pause strategy
- Resume strategy
- Retire strategy
- Edit metadata (optional link to Strategy List)

**Behavior:**

- If state = `paused`, show a subtle banner: “This strategy is paused. Planning is disabled.”
- If state = `retired`, show a red banner: “This strategy is retired. Historical data only.”

### 4.2 Performance Module

**Purpose:** Show how the strategy performs financially over time.

**Inputs:** PnL trend (from StrategyHealth), Win rate, Drawdown, Best/worst cycles, Position history

**UI Elements:**

- PnL Sparkline (last 30–90 trades)
- Win Rate Card
- Max Drawdown Card
- Best Cycle / Worst Cycle Cards
- Recent PnL Table (optional)

**Behavior:**

- Sparkline uses subtle green/gray tones
- No hype, no bright colors
- All numbers are contextualized (e.g., “last 30 trades”)

### 4.3 Discipline Module

**Purpose:** Show how disciplined the user is when executing this strategy.

**Inputs:** Discipline trend (from StrategyHealth), Violations breakdown, Streaks, Journal entries

**UI Elements:**

- Discipline Trendline (last 30 trades)
- Violations Breakdown Pie — Adherence / Timing / Risk
- Streak Indicators — Clean cycle streak, Adherence streak, Risk discipline streak
- Recent Discipline Table (last 5 trades)

**Behavior:**

- If discipline trend is declining, show a subtle warning flag
- If streaks are strong, show a subtle green indicator
- No prescriptive language — only descriptive

### 4.4 Regime Module

**Purpose:** Show how the strategy behaves across market regimes.

**Inputs:** Regime performance (from StrategyHealth), Regime discipline (from StrategyHealth), Current regime (from RegimeSnapshot)

**UI Elements:**

- Current Regime Card — “Current regime: Low Volatility (IV Rank 12)”
- Regime Performance Table — PnL / Win rate / Avg discipline
- Regime Weakness Flags — e.g., “Underperforms in High Volatility”

**Behavior:**

- Weakness flags are descriptive, not prescriptive
- Regime performance is grouped by regime name

### 4.5 Backtest Module

**Purpose:** Show cloud backtest results for this strategy.

**Inputs:** `strategyBacktestResults`, `strategyBacktestJobs`

**UI Elements:**

- Last Cloud Backtest Summary — PnL / Win rate / Drawdown / Regime breakdown
- Backtest History List
- Actions: Run cloud backtest / Re-run last backtest / Compare last 3 backtests (Phase 5.5+)

**Behavior:**

- If no backtests exist, show a calm empty state
- Backtest results are displayed in the same visual language as live performance

### 4.6 Actions Module

**Purpose:** Provide lifecycle and planning actions.

**Actions:**

- Pause strategy
- Resume strategy
- Retire strategy
- Open Planner (pre-filtered for this strategy)
- Run cloud backtest

**Behavior:**

- Retire requires confirmation
- Planner opens with strategy pre-selected
- Cloud backtest opens the job creation modal

## 5. Navigation

**Entry Points:** Strategy List → Strategy Cockpit; Planner → “View Strategy”; Journal Entry → “View Strategy”; Behavior Dashboard → “View Strategy”

**Exit Points:** Back to Strategy List; Into Planner; Into Cloud Backtest screen; Into Journal filtered by strategy

## 6. Performance Considerations

- All modules load independently using `StreamBuilder` or `FutureBuilder`
- StrategyHealth is pre-aggregated (Phase 5.2)
- No heavy client-side aggregation
- Backtest results are paginated

## 7. Completion Criteria

The Strategy Cockpit is complete when:

- All six modules are implemented
- Strategy state changes are reflected instantly
- Planner respects strategy state and constraints
- Backtest results appear in the cockpit
- Regime context is visible
- Discipline and performance trends are accurate
- All navigation flows work cleanly

---

If you want, I can now generate:

- UI widget tree for the Strategy Cockpit
- Folder structure for Phase 5.3
- Dart view models / providers
- Mock data for early development

Just tell me what you want next.
