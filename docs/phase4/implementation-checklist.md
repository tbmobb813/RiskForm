# Phase 4 Implementation Checklist

This document outlines all required implementation tasks for Phase 4, including cloud backtesting, UI integration, and deployment.

---

## 1. Cloud Worker Implementation

### 1.1 Choose Execution Environment
- [ ] Firebase Functions (TypeScript)
- [ ] Cloud Run (Dart container)
- [ ] Confirm engineVersioning strategy

### 1.2 Implement Server-Side Backtest Engine
- [ ] Implement `runBacktestEngine()` in TypeScript
  OR
- [ ] Expose Dart BacktestEngine via Cloud Run HTTP endpoint
- [ ] Ensure deterministic behavior
- [ ] Add engineVersion to all results

### 1.3 Worker → Firestore Integration
- [ ] Read job document
- [ ] Validate config + userId
- [ ] Mark job as `running`
- [ ] Execute engine
- [ ] Write `backtestResults/{jobId}`
- [ ] Mark job as `completed` or `failed`
- [ ] Write errorMessage on failure

### 1.4 Logging & Observability
- [ ] Structured logs (JSON)
- [ ] job_started / job_completed / job_failed events
- [ ] Duration metrics
- [ ] Error classification
- [ ] Cloud Logging dashboard

---

## 2. Client Integration (Flutter)

### 2.1 CloudBacktestService
- [x] Submit job
- [x] Watch job status
- [x] Fetch result
- [x] List user jobs

### 2.2 Cloud Job Status Screen
- [x] Real-time job status
- [x] submittedAt / startedAt / completedAt
- [x] Error display
- [x] "View Full Results" button

### 2.3 Cloud Backtest Result Screen
- [ ] Reuse local BacktestResult UI
- [ ] Feed from CloudBacktestResult
- [ ] Add "Engine Version" badge

### 2.4 Cloud Backtest History Screen
- [ ] List jobs by submittedAt
- [ ] Status chips (queued, running, completed, failed)
- [ ] Tap → open result or status screen

### 2.5 Add "Run in Cloud" Button
- [x] Add to Backtest screen
- [x] Submit job → show status card
- [x] Tap status card → navigate to CloudJobStatusScreen

---

## 3. Dashboard Integration

### 3.1 Cloud Results in Dashboard
- [ ] Add cloud results as a data source
- [ ] Toggle: Local / Cloud / Mixed
- [ ] Show engineVersion in result cards

### 3.2 Cloud Comparison (Optional)
- [ ] Compare multiple cloud runs
- [ ] Multi-curve equity chart
- [ ] Multi-metric comparison table

---

## 4. Settings Panel

### 4.1 Cloud Backtesting Settings
- [ ] Default engineVersion
- [ ] Default compute mode (local vs cloud)
- [ ] Max concurrent jobs
- [ ] Job retention policy

---

## 5. Deployment & Testing

### 5.1 Deploy Worker
- [ ] Deploy TypeScript worker OR Dart Cloud Run container
- [ ] Configure environment variables
- [ ] Validate Firestore permissions

### 5.2 End-to-End Testing
- [ ] Submit job from app
- [ ] Watch job run
- [ ] Fetch result
- [ ] Validate correctness vs local engine
- [ ] Load test with multiple jobs

---

## Summary

Phase 4 is complete when:
- Cloud worker runs deterministically
- Jobs flow end-to-end
- Results appear in the app
- Dashboard supports cloud results
- UI supports job history + status
- Observability is in place

This checklist ensures a clean, scalable, production-ready Phase 4.
