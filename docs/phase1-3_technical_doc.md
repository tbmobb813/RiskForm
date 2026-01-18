# Phase 1–3 Technical Documentation

This document describes the full architecture and specifications for the Planner MVP across Phases 1–3, including engines, lifecycle logic, analytics, journaling, discipline scoring, and strategy comparison.

---

# 1. Backtest Engine Specification

## Purpose

The Backtest Engine simulates the Wheel strategy lifecycle over historical data, producing deterministic, reproducible results for analytics, comparison, and journaling.

---

## Inputs

### BacktestConfig

- `symbol`
- `startingCapital`
- `strategyId`
- `label` (optional)
- `dte`
- `strikeSelectionRule`
- `premiumModel`
- `assignmentModel`
- `rollRules`
- `riskSettings`
- `notes` (optional)

---

## Outputs

### BacktestResult

- `configUsed` (snapshot of BacktestConfig)
- `equityCurve`
- `maxDrawdown`
- `totalReturn`
- `cyclesCompleted`
- `notes`
- `cycles: List<CycleStats>`
- `avgCycleReturn`
- `avgCycleDurationDays`
- `assignmentRate`

### Regime Analytics

- `uptrendAvgCycleReturn`
- `downtrendAvgCycleReturn`
- `sidewaysAvgCycleReturn`
- `uptrendAssignmentRate`
- `downtrendAssignmentRate`
- `sidewaysAssignmentRate`

---

## Pricing Model

- Uses historical OHLC data.
- Option premium = Black‑Scholes approximation + IV adjustment.
- CSP premium and CC premium computed at entry.
- Time decay applied daily.

---

## Assignment Rules

- CSP assignment if underlying closes below strike on expiration.
- CC called away if underlying closes above strike on expiration.
- Early assignment ignored.

---

## Expiration Rules

- Options expire at end of DTE window.
- Expiration triggers:
  - CSP → assignment or expire OTM  
  - CC → called away or expire OTM

---

## Cycle Detection

A cycle begins when a CSP is opened and ends when the CC is closed or expires.

---

# 2. Cycle Lifecycle Specification

## Purpose

Defines the Wheel strategy lifecycle and how cycles are tracked.

---

## States

### 1. CSP Open

- Capital reserved.
- Premium collected.
- DTE countdown begins.

### 2. CSP Expiration

- If price > strike → CSP expires OTM.
- If price ≤ strike → assignment.

### 3. CC Open

- Shares covered.
- Premium collected.

### 4. CC Expiration

- If price < strike → CC expires OTM.
- If price ≥ strike → called away.

---

## CycleStats

- `cycleId` (UUID)
- `index`
- `startEquity`
- `endEquity`
- `durationDays`
- `hadAssignment`
- `dominantRegime`
- `outcome: CycleOutcome`

### CycleOutcome

- `expiredOTM`
- `assigned`
- `calledAway`

---

# 3. Journal Specification

## Purpose

Defines how simulation and live trading events are recorded in a unified, structured journal.

---

## JournalEntry

- `id`
- `timestamp`
- `type`  
  - `"cycle"`  
  - `"assignment"`  
  - `"calledAway"`  
  - `"backtest"`  
  - `"liveTrade"`
- `data: Map<String, dynamic>`

---

## Required Fields

### Cycle entries

- `cycleId`
- `symbol`
- `cycleIndex`
- `cycleReturn`
- `durationDays`
- `hadAssignment`
- `dominantRegime`
- `outcome`

### Assignment entries

- `cycleId`
- `symbol`
- `price`
- `strike`

### Called‑away entries

- `cycleId`
- `symbol`
- `price`
- `strike`

### Backtest entries

- `totalReturn`
- `maxDrawdown`
- `cyclesCompleted`
- `avgCycleReturn`
- `assignmentRate`

### Live trades

- `symbol`
- `price`
- `quantity`
- `strike` (optional)
- `expiry` (optional)
- `"live": true`

---

# 4. Discipline Model Specification

## Purpose

Quantifies user behavior over time using journal entries.

---

## DisciplineScore

- `score` (0–100)
- `planAdherence`
- `cycleQuality`
- `assignmentBehavior`
- `regimeAwareness`

---

## Sub‑Score Definitions

### 1. Plan Adherence (35%)

Completed cycles / total cycles.

### 2. Cycle Quality (25%)

Maps average cycle return into 0–1 range.

### 3. Assignment Behavior (20%)

Called‑away events / assignments.

### 4. Regime Awareness (20%)

Penalizes poor performance in downtrends.

---

## Daily Discipline Snapshot

- `date`
- `score`
- `cyclesCompleted`
- `assignments`
- `calledAway`

---

## Streaks

- `disciplineStreakDays`
- `cleanCycleStreak`
- `noAssignmentStreak`

---

## Habits

- `cleanCycleRate`
- `assignmentAvoidanceRate`
- `planAdherenceRate`

---

# 5. Strategy Comparison Specification

## Purpose

Allows multiple configurations to be backtested and compared side‑by‑side.

---

## ComparisonConfig

- `configs: List<BacktestConfig>`

## ComparisonResult

- `results: List<BacktestResult>`

---

## Comparison Metrics

- Total return  
- Max drawdown  
- Avg cycle return  
- Assignment rate  
- Equity curve  
- Drawdown curve  

---

## Equity Curve Alignment

- Curves aligned by index (day 0 → day N).
- Shorter curves padded or truncated.

---

# 6. Regime Classification Rules

## Purpose

Classifies historical price action into regimes for analytics and cycle tagging.

---

## Inputs

- Historical OHLC data  
- Lookback window (default: 10 days)  
- Uptrend threshold: +3%  
- Downtrend threshold: –3%  

---

## Regime Types

- `uptrend`
- `downtrend`
- `sideways`

---

## Algorithm

1. Compute rolling return over lookback window.  
2. If return ≥ upThreshold → uptrend.  
3. If return ≤ downThreshold → downtrend.  
4. Else → sideways.  
5. Merge consecutive segments of same regime.  
6. Map cycles to regimes by overlap.  

---

## RegimeSegment

- `regime`
- `startDate`
- `endDate`
- `startIndex`
- `endIndex`

---

# End of Phase 1–3 Technical Documentation
