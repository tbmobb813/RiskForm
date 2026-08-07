# RiskForm

**An options scenario simulator — stress-test your strategy before you risk capital.**

RiskForm lets systematic options traders run a strategy through historical market regimes (uptrend, downtrend, sideways) before putting real money behind it. It models **time, state, and risk**, not hype or prediction.

The system includes:

- A full Wheel lifecycle simulator
- Realistic option pricing & assignment logic
- Regime-aware analytics and historical-regime replay
- Strategy comparison
- Live regime, planner-hint, recommendation, and narrative engines
- Automated journaling with sim-driven discipline scoring
- A calm, cockpit-style UI

This README provides an overview of the architecture, current state, and where the product is headed. For the phased business roadmap, see [`ROADMAP.md`](./ROADMAP.md).

---

## 🚀 Project Vision

RiskForm is built around a simple philosophy:

> **Know how a strategy behaves before you fund it.**

The app helps traders:

- simulate realistic Wheel campaign outcomes
- replay a strategy against historical regime windows
- understand regime-dependent behavior (assignment rates, cycle returns, drawdowns)
- compare strategies side by side
- see how simulated discipline compares to actual behavior

The goal is not to predict markets — it's to give traders a rigorous way to **stress-test a strategy against how markets have actually behaved**, before capital is at risk.

---

## 🧱 Architecture Overview

The system is organized into five pillars:

### **1. Engines**

- Pricing engine
- Assignment engine
- Lifecycle engine
- Backtest engine
- Regime classifier

### **2. State & Persistence**

- Planner state
- Backtest state
- Firestore persistence
- Account context

### **3. Analytics**

- Cycle-level analytics
- Performance dashboard
- Regime segmentation
- Strategy comparison

### **4. Journal**

- Automated sim entries
- Live-trade ingestion (CSV import from major brokers)
- Discipline scoring
- Streaks & habits

### **5. UI**

- Planner
- Dashboard
- Journal
- Comparison
- Discipline analytics

---

## 📦 Folder Structure

lib/ models/ backtest/ analytics/ journal/ trade/ services/ engines/ analytics/ journal/ state/ screens/ planner/ performance/ comparison/ journal/ widgets/ charts/

---

## 🧭 Current State

Engines, regime classification, analytics, journal, and strategy comparison are built and complete. Beyond that, the system already has **live** regime classification, planner hints, a strategy recommendations engine, and a strategy narrative engine running against real-time data (see `docs/SYSTEM_OVERVIEW.md` for the full technical picture).

The forward-looking business roadmap — what gets built next, in what order, and what's explicitly deprioritized — lives in [`ROADMAP.md`](./ROADMAP.md), not here. That file is the current source of truth for phase planning; treat any other phase numbering in `/docs` as historical design context, not active status.

---

## 📊 Key Features

## **Wheel Strategy Simulator**

- Realistic CSP/CC lifecycle
- Assignment & expiration logic
- Premium modeling
- Cycle detection
- Equity & drawdown curves

## **Regime-Aware Analytics**

- Uptrend / Downtrend / Sideways segmentation
- Regime-specific cycle returns
- Regime-specific assignment rates
- Historical-regime replay: pick a past regime window and run a hypothetical campaign through it

## **Performance Dashboard**

- Total return
- Max drawdown
- Cycle stats
- Equity curve
- Drawdown curve
- Regime breakdown

## **Strategy Comparison**

- Compare multiple configs
- Side-by-side metrics
- Multi-curve equity chart

## **Journal System**

- Automated sim entries
- Live-trade ingestion
- Unified journal structure
- Entry detail view
- Filtering by type

## **Discipline Engine**

- Discipline scoring derived from simulated-vs-actual behavior
- Daily snapshots
- Streaks
- Habit tracking

---

## 🧪 Technology Stack

- **Flutter** (UI + state management)
- **Dart** (engines + analytics)
- **Riverpod** (state management)
- **Firestore** (persistence)
- **Custom engines** (pricing, lifecycle, backtesting)

---

## 🧩 Core Concepts

### **Lifecycle Modeling**

The Wheel is treated as a deterministic state machine:

- CSP open → CSP expiration → assignment → CC open → CC expiration → called away

### **Regime Awareness**

Market behavior affects strategy behavior:

- Uptrend
- Downtrend
- Sideways

### **Sim-Driven Discipline**

The system tracks:

- discipline (derived automatically from simulated vs. actual behavior, not manual mood logs)
- habits
- streaks
- adherence to plan

### **Unified Journal**

Sim + live trades share the same schema.

---

## 🌐 Platform

Web is the active build/deploy target (Flutter web, deployed via Firebase Hosting). Android, iOS, macOS, Linux, and Windows build targets exist in this repo but are **deprioritized and frozen** — no active CI or development investment goes into them for now. See `ROADMAP.md` for the platform-consolidation decision.

---

## 🧊 Frozen / Out of Scope

The following are explicitly **not** getting further investment right now:

- **Cloud distributed backtesting** — built and deployed (`cloud_worker/` on Google Cloud Run), but frozen: no new features, no roadmap dependency on it until a later phase's gate clears.
- **Live broker execution sync** — not built. Only CSV import from broker exports exists today.
- **Multi-strategy orchestration** — not built beyond docs-level design notes.

Full detail and rationale in [`ROADMAP.md`](./ROADMAP.md).

---

## 💳 Pricing

The simulator core is free. Deeper regime-scenario analysis and strategy comparison are planned to sit behind a future Pro tier once willingness-to-pay is validated — see `ROADMAP.md` Phase 2 for the pricing plan and gating approach. No billing exists yet.

---

## 📘 Documentation

Technical documentation lives in `/docs`, including phase-by-phase specs for the engines, regime classification, cloud worker, and live intelligence systems built to date. For current product positioning and business phase status, `README.md` (this file) and `ROADMAP.md` are authoritative; treat phase numbering inside individual `/docs` files as historical design context.

---

## 🧑‍💻 Contributing

This project is currently under active development by the founder.
External contributions may be opened in future phases.

---

## 📄 License

Proprietary — All rights reserved.
