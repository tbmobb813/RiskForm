# Planner Architecture

The Planner is the user-facing workflow for designing, simulating, and saving Wheel strategy trades.  
It acts as the bridge between user intent and the deterministic engines that power the system.

---

## Core Responsibilities
- Collect user inputs (symbol, DTE, strikes, risk settings)
- Build a `BacktestConfig`
- Run the Backtest Engine
- Display payoff, risk, and lifecycle insights
- Save the plan to persistence
- Feed the Dashboard and Journal

---

## Architecture Layers

### 1. UI Layer (`/screens/planner`)
- Strategy selector
- Trade planner inputs
- Payoff visualization
- Risk summary
- Save plan screen

### 2. State Layer (`/state/planner`)
- Holds `PlannerState`
- Tracks:
  - strategy metadata
  - trade inputs
  - payoff results
  - risk results
  - notes & tags
  - loading/error states

### 3. Engine Layer (`/services/engines`)
- Pricing engine
- Lifecycle engine
- Backtest engine
- Regime classifier

### 4. Persistence Layer (`/services/persistence`)
- Firestore repository
- Saves:
  - plan metadata
  - configs
  - backtest results

---

## Data Flow
User Input → PlannerState → BacktestConfig → BacktestEngine → BacktestResult → UI + Journal + Dashboard

---

## Design Principles
- Deterministic engines
- Typed models
- Clear separation of UI vs logic
- Planner is “dumb” — engines do the work
- Reproducibility over convenience
