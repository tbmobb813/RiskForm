# Phase 5 — Strategy Intelligence & Lifecycle Engine
_Specification Document_

## 1. Purpose

Phase 5 elevates the platform from trade‑level discipline to **strategy‑level intelligence**.
The goal is to unify planning, execution, journaling, cloud backtesting, and behavioral analytics under a **strategy‑centric architecture**.

This phase introduces:

- Strategy lifecycle management
- Strategy health analytics
- Strategy cockpit UX
- Strategy‑aware planning
- Strategy‑level cloud orchestration

This enables users to understand, maintain, and improve their strategies over time.

## 2. Scope

Phase 5 includes:

1. Strategy Lifecycle Engine
2. Strategy Analytics & Health Engine
3. Strategy Cockpit UX
4. Strategy‑Aware Planning & Hints
5. Strategy‑Level Cloud Orchestration

Out of scope:

- Live brokerage integration
- Automated trading
- Social features
- Portfolio allocation engine

## 3. Architecture Overview

Phase 5 introduces a new domain layer centered on `Strategy`.

### Core Entities

- `Strategy`
- `StrategyLifecycleEvent`
- `StrategyHealthSnapshot`
- `TradePlan`
- `Position`
- `JournalEntry`
- `DisciplineScore`
- `BacktestJob` / `BacktestResult`
- `RegimeSnapshot`

### Core Idea

All analytics, feedback, and orchestration flow **through the strategy**.

## 4. Data Model Additions

### 4.1 Strategy Document

```
strategies/{strategyId}
  name: string
  state: "active" | "paused" | "retired" | "experimental"
  createdAt: timestamp
  retiredAt?: timestamp
  tags: string[]
  constraints: {
    maxRisk?: number
    allowedRegimes?: string[]
    maxDrawdown?: number
  }
```

### 4.2 Strategy Lifecycle Events

```
strategyEvents/{eventId}
  strategyId: string
  type: "created" | "activated" | "paused" | "resumed" | "retired"
  timestamp: timestamp
  reason?: string
```

### 4.3 Strategy Health Snapshot

```
strategyHealth/{strategyId}
  updatedAt: timestamp
  pnlTrend: number[]        // compressed
  disciplineTrend: number[] // last 30 trades
  regimePerformance: {
    [regimeName: string]: {
      pnl: number
      winRate: number
      avgDiscipline: number
    }
  }
  flags: string[]           // warnings, notes
```

### 4.4 Strategy-Level Backtest Jobs

```
strategyBacktestJobs/{jobId}
  strategyId: string
  createdAt: timestamp
  status: "queued" | "running" | "completed" | "failed"
  parameters: {...}
```

### 4.5 Strategy-Level Backtest Results

```
strategyBacktestResults/{jobId}
  strategyId: string
  completedAt: timestamp
  summary: {...}
  regimeBreakdown: {...}
  pnlCurve: number[]
```

## 5. Sub‑Phase Specifications

### 5.1 Strategy Lifecycle Engine

Purpose
Make `Strategy` a first‑class, stateful entity with constraints and lifecycle events.

Features
- Create, pause, resume, retire strategies
- Enforce constraints in Planner
- Track lifecycle events
- Expose strategy state to UI

State Machine

```
created → active → paused → active → retired
```

Planner Enforcement
- If strategy is `paused` → show warning
- If `retired` → disable planning
- If regime not allowed → show contextual hint

### 5.2 Strategy Analytics & Health Engine

Purpose
Compute strategy‑level performance, discipline, and regime behavior.

Inputs
- Journal entries
- Discipline scores
- Positions
- Backtest results
- Regime snapshots

Outputs
- `strategyHealth/{strategyId}` snapshot
- Flags (e.g., “underperforming in high IV”)
- Trends (PnL, discipline)
- Regime performance breakdown

Engine Responsibilities
- Aggregate last 30–90 trades
- Compute discipline trend
- Compute PnL trend
- Compute regime performance
- Detect deterioration or drift
- Write snapshot document

### 5.3 Strategy Cockpit UX

Purpose
Provide a cockpit‑style screen for each strategy.

Sections

1. Status & Constraints — State (active/paused/retired), Constraints, Flags
2. Performance — PnL trend, Win rate, Drawdown, Best/worst cycles
3. Discipline — Discipline trend, Violations breakdown, Streaks
4. Regime Behavior — Performance by regime, Discipline by regime, Weaknesses
5. Actions — Pause strategy, Resume strategy, Run cloud backtest, Open Planner pre-filtered

### 5.4 Strategy‑Aware Planning & Hints

Purpose
Make the Planner context‑aware without being prescriptive.

Enhancements
- Pre-filter by strategy
- Show strategy health summary
- Show regime context
- Show soft hints:
  - “This strategy struggles in high IV.”
  - “Your timing discipline has slipped recently.”

Rules
- No black-box recommendations
- All hints must be explainable
- All hints must be traceable to StrategyHealth

### 5.5 Strategy-Level Cloud Orchestration

Purpose
Elevate cloud backtesting to strategy-level batch runs.

Capabilities
- Run batch backtests per strategy
- Run across regimes
- Run across parameter sets
- Store results in strategy-level collections

UX
- From Strategy Cockpit:
  - “Run cloud backtest”
  - “Re-run last batch”
  - “Compare last 3 runs”

## 6. Execution Order

1. Strategy Lifecycle Engine
2. Strategy Analytics Engine
3. Strategy Cockpit UX
4. Strategy-Aware Planner
5. Strategy-Level Cloud Orchestration

## 7. Risks & Mitigations

Risk: Strategy analytics becomes slow
Mitigation:
- Use compressed arrays
- Pre-aggregate snapshots
- Limit queries to last 30–90 trades

Risk: Hints feel prescriptive
Mitigation:
- Keep hints descriptive, not directive
- Always show source of hint

Risk: Cloud orchestration becomes complex
Mitigation:
- Start with single-strategy batch runs
- Add multi-regime later

## 8. Deliverables

- New Firestore collections
- Strategy lifecycle engine
- Strategy analytics engine
- Strategy cockpit screen
- Strategy-aware planner enhancements
- Strategy-level cloud orchestration
- Documentation for all new models and flows

## 9. Completion Criteria

Phase 5 is complete when:

- Strategies have lifecycle states
- Strategy health snapshots update automatically
- Strategy cockpit is fully functional
- Planner shows strategy-aware context
- Cloud backtests can run at strategy level
- User can evaluate and improve strategies over time

---

If you want, I can now generate:

- A Phase 5 folder structure
- A Phase 5 implementation roadmap
- A Phase 5 kickoff checklist
- Or the Strategy Lifecycle Engine spec as the first sub-phase

Just tell me what you want next.
