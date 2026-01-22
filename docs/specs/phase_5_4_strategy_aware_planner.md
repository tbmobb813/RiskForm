# PHASE 5.4 — Strategy‑Aware Planner Integration
*Production Specification — Final Version*

## 1. Purpose

Phase 5.4 connects the **Strategy Cockpit** to the **Planner**, enabling a fully strategy‑aware execution loop.

This phase ensures that:

- Every trade executed from the Planner is **bound to a strategy**
- Strategy constraints, discipline flags, and regime context are **enforced at execution time**
- Every execution updates the **active cycle**
- Every cycle update triggers a **StrategyHealthSnapshot recompute**
- The Cockpit reflects the updated health in real time

This phase completes the **closed behavioral loop**:

**Cockpit → Planner → Execution → Cycle → Health → Cockpit**

## 2. High‑Level Architecture

```
Strategy Cockpit
      │
      ▼
Planner (with Strategy Context)
      │
      ▼
ExecutionService
      │
      ▼
StrategyCycleService
      │
      ▼
StrategyHealthService (dirty flag)
      │
      ▼
Cloud Function Worker
      │
      ▼
StrategyHealthSnapshot
      │
      ▼
Strategy Cockpit (reactive UI)
```

Each layer has a single responsibility and no cross‑contamination.

## 3. Data Contracts

### 3.1 PlannerStrategyContext
Passed from Cockpit → Planner.

Contains:

- strategyId
- strategyName
- state
- tags
- constraints
- disciplineFlags
- currentRegime
- constraintsSummary
- updatedAt

This is the **context envelope** that makes Planner strategy‑aware.

### 3.2 StrategyExecutionRequest
Built by Planner → sent to ExecutionService.

Contains:

- strategyContext
- execution payload (symbol, type, strike, expiry, premium, qty, timestamp)
- optional cycleId

This is the **execution envelope**.

### 3.3 StrategyCycle
Represents a single behavioral cycle.

Contains:

- lifecycle state
- executions
- realized/unrealized PnL
- disciplineScore
- dominantRegime
- tradeCount
- timestamps

### 3.4 StrategyHealthSnapshot
Aggregated health state consumed by Cockpit.

Contains:

- pnlTrend
- disciplineTrend
- regimePerformance
- cycleSummaries
- regimeWeaknesses
- currentRegime
- currentRegimeHint
- updatedAt

## 4. Planner Integration

### 4.1 Cockpit → Planner Navigation

When user taps “Open Planner”:

```
Navigator.pushNamed(
  '/planner',
  arguments: PlannerStrategyContext(...)
);
```

Planner receives context via `ModalRoute`.

### 4.2 Planner Notifier Stores Context

Planner stores:

- strategyContext
- tradeInputs
- isSubmitting
- errorMessage

### 4.3 Planner Builds Execution Request

Planner constructs:

```
StrategyExecutionRequest(
  strategyContext: ...,
  execution: {
    timestamp,
    symbol,
    type,
    strike,
    expiry,
    premium,
    qty
  }
)
```

This is the **canonical execution payload**.

### 4.4 Planner Calls ExecutionService

```
await _executionService.executeStrategyTrade(request)
```

Planner handles:

- success → reset inputs
- failure → show error

## 5. Execution Layer

### 5.1 ExecutionService Responsibilities

1. Validate strategy state
2. Validate constraints
3. Write journal entry
4. Append execution to active cycle
5. Mark health dirty

All done inside a Firestore transaction.

### 5.2 Constraint Validation

ExecutionService enforces:

- maxRisk
- maxPositions
- timing rules
- discipline flags

This ensures Planner cannot violate strategy rules.

## 6. Cycle Layer

### 6.1 StrategyCycleService Responsibilities

1. Resolve active cycle
2. Create new cycle if none exists
3. Append execution
4. Recompute metrics using analyzers
5. Write updated cycle

### 6.2 Analyzer Integration

CycleService calls:

- `StrategyPerformanceAnalyzer.computeCyclePerformance()`
- `StrategyDisciplineAnalyzer.computeCycleDiscipline()`
- `StrategyRegimeAnalyzer.computeCycleRegime()`

These produce:

- realized/unrealized PnL
- disciplineScore
- dominantRegime

This is the **behavioral engine**.

## 7. Health Layer

### 7.1 StrategyHealthService Responsibilities

1. Mark health dirty (in transaction)
2. Cloud worker recomputes full snapshot
3. Write final StrategyHealthSnapshot

### 7.2 Cloud Worker Responsibilities

1. Listen for `dirty == true`
2. Load all cycles
3. Aggregate:
   - pnlTrend
   - disciplineTrend
   - regimePerformance
   - cycleSummaries
   - weakness flags
   - currentRegimeHint
4. Write snapshot
5. Clear dirty flag

This ensures health recompute is **asynchronous and scalable**.

## 8. Cockpit Layer

Cockpit viewmodels listen to:

- `strategyHealth/{strategyId}`
- `strategyCycles/{strategyId}`
- `strategy/{strategyId}`

When health updates:

- Performance module updates
- Discipline module updates
- Regime module updates
- Weakness flags update
- Header state remains consistent

This completes the **closed loop**.

## 9. End‑to‑End Flow Summary

1. User opens Planner from Cockpit
2. User builds a trade
3. User executes trade → Planner builds `StrategyExecutionRequest`
4. ExecutionService validates + writes journal + updates cycle + marks health dirty
5. Cloud worker recomputes health → writes `StrategyHealthSnapshot`
6. Cockpit updates automatically

## 10. Completion Criteria

Phase 5.4 is complete when:

- Planner receives strategy context
- Planner builds StrategyExecutionRequest
- ExecutionService validates + routes
- StrategyCycleService updates cycles with analyzers
- StrategyHealthService marks dirty
- Cloud worker recomputes health
- Cockpit updates in real time
- No manual refresh required
- No stale state anywhere

This completes the **Strategy‑Aware Execution Loop**.

## 11. What’s Next

You are now ready for:

- Phase 5.5 — Backtest Comparison Engine
- Phase 5.6 — Strategy Health Score

Choose the next direction and the implementation plan will be prepared.
