# RiskForm

**RiskForm is a deterministic risk-first strategy framework for systematic options income.**

It is not a signal generator.
It is not a prediction engine.
It does not chase returns.

RiskForm exists to **formalize risk**, **constrain behavior**, and **compose strategies safely**.

---

## Philosophy

Most trading systems fail for the same reasons:

* Strategies are defined loosely
* Risk is implicit instead of explicit
* “Edge” is confused with luck
* Strategy logic and execution logic are entangled
* New strategies are bolted on instead of integrated

RiskForm rejects this approach.

**In RiskForm, risk is the primary abstraction.**

Every strategy is treated as a **risk contract** with:

* Defined payoff bounds
* Known failure modes
* Explicit assignment logic
* Enforced guardrails

Returns are an outcome — not the objective.

---

## Core Principles

### 1. Determinism Over Discretion

Given the same inputs, a RiskForm strategy produces the same outputs.
There is no “feel”, no overrides, no intuition hooks.

If behavior cannot be formalized, it does not belong in the system.

---

### 2. Strategies Are Engines, Not Ideas

A strategy in RiskForm is an **engine** with a fixed interface.

Each engine must declare:

* Entry conditions
* Exit conditions
* Payoff formulas
* Risk formulas
* Assignment behavior
* Capital requirements

If it cannot be expressed this way, it is not a valid strategy.

---

### 3. Risk Is Defined Before Return

Every engine must answer:

* *What can go wrong?*
* *How bad can it get?*
* *Under what conditions does failure accelerate?*

Only after these are defined does the system care about yield.

---

### 4. Guardrails Are Non-Negotiable

RiskForm enforces constraints at the system level:

* Position sizing limits
* Volatility thresholds
* Correlation exposure
* Capital allocation rules

Strategies do not bypass guardrails.
Meta-strategies do not weaken them.

---

### 5. Composition Without Mutation

Complex behavior is achieved through **composition**, not modification.

* Credit spreads remain credit spreads
* Covered calls remain covered calls
* The Wheel is a **meta-strategy**, not a new engine

This ensures correctness, testability, and extensibility.

---

## Architecture Overview

RiskForm is structured around three layers:

### Strategy Engines

Atomic, self-contained implementations of trading logic
(e.g. Cash-Secured Puts, Credit Spreads, Covered Calls)

Each engine:

* Implements the StrategyEngineInterface
* Knows nothing about other strategies
* Exposes standardized outputs

---

### Meta-Strategy Controllers

Orchestrators that coordinate engines without altering them.

Examples:

* Wheel Strategy
* Income Rotation
* Risk-Adaptive Allocation

Meta-strategies decide *when* and *how* to deploy engines — never *how engines work*.

---

### Risk & Control Layer

System-wide enforcement of:

* Capital constraints
* Exposure limits
* Kill conditions
* Assignment handling
* State transitions

This layer always has veto power.

---

## What RiskForm Is Not

* ❌ A backtest toy
* ❌ A black-box AI trader
* ❌ A signal marketplace
* ❌ A prediction system
* ❌ A “get rich quick” platform

RiskForm assumes markets are uncertain and treats that uncertainty with respect.

---

## Intended Users

RiskForm is built for:

* Engineers who think in systems
* Traders who value survival over excitement
* Builders who want correctness before optimization

If you are looking for shortcuts, this is the wrong tool.

If you are building something meant to last, you are in the right place.

---

## The Goal

> **To make incorrect risk behavior structurally impossible.**

When a strategy fails in RiskForm, it should fail:

* Within known bounds
* For known reasons
* Without cascading damage

That is not pessimism.

That is engineering.

---

### Status

RiskForm is under active development.
Interfaces are treated as contracts.
Breaking changes are intentional and rare.

---

**RiskForm**
*Structure before speculation. Risk before reward.*
