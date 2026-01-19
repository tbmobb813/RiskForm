# Cycle State Machine Diagram

```mermaid
stateDiagram-v2
    [*] --> CSP_Open

    CSP_Open --> CSP_Expired_OTM: Price > Strike
    CSP_Open --> Assigned: Price ≤ Strike

    CSP_Expired_OTM --> CC_Open
    Assigned --> CC_Open

    CC_Open --> CC_Expired_OTM: Price < Strike
    CC_Open --> Called_Away: Price ≥ Strike

    CC_Expired_OTM --> Cycle_End
    Called_Away --> Cycle_End

Notes
Every cycle produces a CycleStats object

Each cycle has a unique cycleId

Regime is mapped by date overlap