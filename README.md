# Planner MVP — Wheel Strategy Simulator & Discipline Engine

A discipline‑first trading platform designed to help small‑account traders execute the Wheel strategy with clarity, structure, and behavioral reinforcement.  
This project models **time, state, and discipline**, not hype or prediction.

The system includes:

- A full Wheel lifecycle simulator  
- Realistic option pricing & assignment logic  
- Regime‑aware analytics  
- Strategy comparison  
- Automated journaling  
- Discipline scoring  
- Habit tracking  
- A calm, cockpit‑style UI  

This README provides an overview of the architecture, features, and development phases.

---

## 🚀 Project Vision

The Planner MVP is built around a simple philosophy:

> **Trading success is a behavioral problem, not a P/L problem.**

The app helps traders:

- plan trades  
- simulate realistic outcomes  
- understand regime‑dependent behavior  
- track discipline  
- compare strategies  
- build long‑term habits  

The goal is not to predict markets — it’s to **reinforce disciplined execution**.

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

- Cycle‑level analytics  
- Performance dashboard  
- Regime segmentation  
- Strategy comparison  

### **4. Journal**

- Automated sim entries  
- Live‑trade ingestion  
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

This structure is optimized for scalability and Phase 4 cloud execution.

---

## 🧭 Development Phases

## **Phase 1 — Planner, Engines, Persistence**

Core foundations.

### Completed

- Planner UI  
- State management  
- Pricing engine  
- Lifecycle engine  
- Payoff chart  
- Firestore persistence  
- Folder structure  
- Account context provider  

---

## **Phase 2 — Wheel Lifecycle, Dashboard, Risk**

Full Wheel modeling + risk exposure.

### Completed

- CSP → assignment → CC → called away  
- Cycle modeling  
- Assignment & expiration logic  
- Dashboard risk exposure  
- Strategy recommendations  
- Initial journal automation  

---

## **Phase 3 — Analytics, Behavior, Comparison**

Intelligence + behavior modeling.

### Completed

- Realistic option pricing  
- Realistic assignment & expiration  
- Cycle‑by‑cycle analytics  
- Performance dashboard  
- Strategy comparison  
- Regime segmentation  
- Journal automation  
- Journal UI  
- Discipline scoring  
- Discipline streaks  
- Habit tracking  
- Pre‑Phase‑4 enhancements:
  - Config snapshot  
  - Cycle IDs  
  - CycleOutcome enum  
  - Backtest labels  

Phase 3 is fully complete.

---

## 📊 Key Features

## **Wheel Strategy Simulator**

- Realistic CSP/CC lifecycle  
- Assignment & expiration logic  
- Premium modeling  
- Cycle detection  
- Equity & drawdown curves  

## **Regime‑Aware Analytics**

- Uptrend / Downtrend / Sideways segmentation  
- Regime‑specific cycle returns  
- Regime‑specific assignment rates  

## **Performance Dashboard**

- Total return  
- Max drawdown  
- Cycle stats  
- Equity curve  
- Drawdown curve  
- Regime breakdown  

## **Strategy Comparison**

- Compare multiple configs  
- Side‑by‑side metrics  
- Multi‑curve equity chart  

## **Journal System**

- Automated sim entries  
- Live‑trade ingestion  
- Unified journal structure  
- Entry detail view  
- Filtering by type  

## **Discipline Engine**

- Discipline scoring  
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

### **Behavioral Reinforcement**

The system tracks:

- discipline  
- habits  
- streaks  
- adherence to plan  

### **Unified Journal**

Sim + live trades share the same schema.

---

## 📘 Documentation

All technical documentation for Phases 1–3 is available in:

- `/docs/phase1-3-technical.md`  
- `/docs/project-overview.md`  

These include:

- Backtest Engine Specification  
- Cycle Lifecycle Specification  
- Journal Specification  
- Discipline Model  
- Strategy Comparison Specification  
- Regime Classification Rules  

---

## 🛣️ Next Steps (Phase 4 Preview)

Phase 4 will introduce:

### **1. Cloud Backtesting Engine**

- Distributed jobs  
- Multi‑symbol  
- Multi‑strategy  
- Persistent results  

### **2. Pro Analytics**

- Volatility clustering  
- Heatmaps  
- Assignment risk curves  
- Capital efficiency scoring  

### **3. Multi‑Strategy Orchestration**

- Wheel + CSP ladder  
- Wheel + PMCC  
- Wheel + covered strangle  

### **4. Live Trading Integration**

- Broker sync  
- Real‑time journal ingestion  
- Sim vs live behavior comparison  

---

## 🧑‍💻 Contributing

This project is currently under active development by the founder.  
External contributions may be opened in future phases.

---

## 📄 License

Proprietary — All rights reserved.
