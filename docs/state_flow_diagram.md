# Planner → Engine → Save → Dashboard (State Flow Diagram)

```mermaid
flowchart LR
    A[Planner UI] --> B[PlannerState]
    B --> C[Build BacktestConfig]
    C --> D[BacktestEngine.run()]
    D --> E[BacktestResult]
    E --> F[Journal Automation]
    E --> G[Dashboard Analytics]
    E --> H[Save Plan to Firestore]
    H --> I[Dashboard Loads Saved Plans]

Explanation
Planner UI collects inputs and updates PlannerState

PlannerState builds a BacktestConfig

Backtest Engine produces a deterministic BacktestResult

Result flows into:

Journal (cycle entries, backtest summary)

Dashboard (performance, risk, lifecycle)

Persistence (saved plan)


---
