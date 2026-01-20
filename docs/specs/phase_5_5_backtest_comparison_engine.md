# PHASE 5.5 — Backtest Comparison Engine & Batch Backtest Orchestration
### Production Specification — Final Version

Date: 2026-01-20

---

## 1. Purpose

Phase 5.5 introduces a Backtest Comparison Engine and a Batch Backtest Orchestrator. The combined feature set enables the Strategy Cockpit to:

- Compare recent backtest runs and surface best/worst configurations.
- Run parameter-sweep batch backtests across configurable grids.
- Detect regime-specific weaknesses and produce cockpit-ready summaries.
- Present results in a calm, cockpit-native UI for fast operator decisions.

The design is deterministic, Firestore-friendly, and operator-grade—suitable for Cloud Functions or Cloud Run workers.

## 2. High-Level Architecture

```
Strategy Cockpit
      │
      ├── Backtest Comparison Module
      │
      └── Batch Backtest Launcher
              │
              ▼
      BatchBacktestService
              │
              ▼
      Firestore (batches + runs)
              │
              ▼
      Cloud Worker (finalizeBatchBacktest)
              │
              ▼
      Batch Summary (best, worst, regime notes)
              │
              ▼
      Cockpit UI (Comparison + Summary Panels)
```

## 3. Firestore Layout

This spec uses two primary collections under `strategyBacktests/{strategyId}`:

3.1 `runs/{runId}` (individual backtest run documents)

Fields:
- `createdAt` (timestamp)
- `parameters` (map) — the parameter set used
- `status` — `queued | running | complete | failed`
- `metrics` — PnL, winRate, maxDrawdown, sharpe, etc.
- `regimeBreakdown` — map of regime -> metrics (pnl, trades)
- `batchId` (optional string) — parent batch

3.2 `batches/{batchId}` (batch orchestration document)

Fields:
- `createdAt` (timestamp)
- `parameterGrid` (array of parameter maps)
- `runIds` (array of runId strings)
- `status` — `queued | running | complete | failed`
- `summary` — object produced when complete (bestConfig, worstConfig, regimeWeaknesses, summaryNote)

## 4. Backtest Comparison Engine

The comparison engine consumes a set of completed `runs` and produces a `BacktestComparisonResult`:

```dart
class BacktestComparisonResult {
  final List<Map<String, dynamic>> runs;
  final Map<String, dynamic>? bestConfig;
  final Map<String, dynamic>? worstConfig;
  final Map<String, dynamic> regimeWeaknesses;
  final String summaryNote;
}
```

### 4.1 Scoring (Best / Worst)

Use a compact, interpretable composite score that balances reward and risk:

score = pnl - maxDrawdown + (winRate * 100)

- `pnl`, `maxDrawdown`, and `winRate` are taken from each run's `metrics` map.
- Higher score → better configuration.

### 4.2 Regime Weakness Detection

Aggregate PnL per regime across all runs and compute averages.

- If average PnL < 0 → note: "Strategy tends to lose in {regime} conditions." 
- If average PnL > 0 → note: "Strategy tends to perform well in {regime} conditions." 

### 4.3 Summary Note

Produce a concise human-friendly summary that:
- States the best configuration and key metrics.
- Points out the weakest configuration.
- Lists regime notes.

## 5. Batch Backtest Orchestration

The orchestrator expands parameter ranges to a Cartesian grid, creates a batch document, and creates `run` documents for each parameter set.

### 5.1 createBatchJob (BatchBacktestService)

Inputs:
- `strategyId` (string)
- `parameterGrid` (List<Map<String, dynamic>>)

Behavior:
1. Create `batches/{batchId}` with `parameterGrid`, `createdAt`, `runIds: []`, `status: queued`.
2. For each parameter set, create `runs/{runId}` with `parameters`, `createdAt`, `status: queued`, `batchId`.
3. Update the batch doc with `runIds`.

The service is Firestore-friendly and uses batched writes where practical to reduce write amplification.

### 5.2 finalizeBatch (worker)

Triggered from an authoritative worker (Cloud Function on run writes, or a polling Cloud Run worker). Behavior:
1. Load `batches/{batchId}` and associated run docs.
2. If no runs are complete → set `status: failed` and short-circuit.
3. Select completed runs and compute comparison summary (best/worst/regimeWeaknesses).
4. Write `summary` and set `status: complete` and `updatedAt`.

Note: worker must be idempotent and tolerate partial writes / replays.

## 6. Cloud Worker — finalizeBatchBacktest

Recommended implementation: Cloud Function (Firestore onWrite) listening to `runs/{runId}`.

Flow:
- On run write, if `status` is `complete`, fetch parent `batch` and all runs.
- If all runs are `complete`, compute summary and update batch.
- If some runs remain incomplete, return (no-op).

Idempotency:
- Use `batchId` and `runId` fields to avoid race conditions.
- Writes to `batches/{batchId}` should be atomic updates replacing `summary` and `status`.

## 7. Parameter Grid Builder (Advanced)

UI responsibilities:
- Allow range selection (start, end, step) for each parameter.
- Provide presets for common strategies.
- Preview generated grid with count and sample rows.
- Export generated grid to `BatchBacktestService.createBatchJob()`.

Data model example:

```dart
class ParameterRange {
 final double start;
 final double end;
 final double step;
}

ParameterRange.expand() → List<double>
```

Grid expansion is a Cartesian product of parameter value lists.

## 8. Backtest Comparison UI

UI panels:
- Best Configuration Card — shows the parameters & key metrics.
- Weak Configuration Card — shows the worst parameters & metrics.
- Regime Weaknesses Card — lists regime notes.
- Summary Card — textual synthesis.
- Comparison Table — runs × metrics × parameters (DataTable).

Design principles:
- Calm spacing and consistent card style to match existing cockpit modules.
- No visual noise; focus on distilled insights by default.

## 9. Security & Operational Considerations

- Worker IAM: ensure the Cloud Function / Cloud Run service account has Firestore read/write only for `strategyBacktests/*` as required.
- Rate limits: batch sizes should be bounded (recommend default 25–100 runs per batch) to avoid Firestore quotas spikes.
- Cost: running large parameter sweeps can generate many reads/writes — advise operators to keep parameter grids focused.
- Observability: worker logs must include `strategyId`, `batchId`, and a summary of writes; enable alerting for repeated failures.

## 10. Testing & Validation

- Unit tests for `BacktestComparisonService` scoring and regime detection.
- Integration tests for `BatchBacktestService.createBatchJob()` creating expected docs.
- Local Cloud Functions emulator or CI-driven integration to validate `finalizeBatchBacktest` behavior.

## 11. Backwards Compatibility

- This feature uses new collections under `strategyBacktests/` and does not change existing data structures.
- Cockpit modules should gracefully handle absence of `summary` or incomplete batches.

## 12. Completion Criteria

Phase 5.5 is complete when:

- `BacktestComparisonService` correctly compares last N runs and returns `BacktestComparisonResult`.
- `BatchBacktestService.createBatchJob()` creates batch + run docs and returns `batchId`.
- `finalizeBatchBacktest` worker finalizes batch doc once runs complete.
- `ParameterGridBuilder` generates deterministic Cartesian grids and can submit to `createBatchJob()`.
- Cockpit displays comparison, summary, and batch progress without manual refresh.

---

If you want, this spec can be extended with an operational playbook (alerts, quotas, rollbacks) or a Phase 5.6 spec for a unified Strategy Health Score.
