# Cloud Backtesting Worker Architecture

The Cloud Worker is the server-side execution engine responsible for running backtests submitted by the client. It processes jobs asynchronously, executes the deterministic Backtest Engine, and stores results for retrieval by the client.

This document defines the architecture, flow, responsibilities, and components of the Cloud Worker.

---

## 1. High-Level Overview

The Cloud Worker system consists of three major components:

1. **Job Store**
   Firestore collection `backtestJobs` containing job metadata and status.

2. **Worker Function**
   A server-side function triggered when a job enters the `"queued"` state.

3. **Result Store**
   Firestore collection `backtestResults` containing completed results.

---

## 2. System Flow

```mermaid
flowchart LR
    A[Client App] --> B[Create Job Document<br/>status = 'queued']
    B --> C[Firestore Trigger<br/>onCreate or onStatusChange]
    C --> D[Cloud Worker]
    D --> E[Run Backtest Engine (Server)]
    E --> F[Write Result Document]
    F --> G[Update Job Status to 'completed']
    G --> H[Client Fetches Result]
```

---

## 3. Cloud Worker Responsibilities

The worker performs the following steps:

### 1. **Validate Job**
- Ensure `configUsed` is valid.
- Ensure `userId` is present.
- Ensure `engineVersion` is supported.

### 2. **Mark Job as Running**
- Set `status = "running"`
- Set `startedAt = now()`

### 3. **Execute Backtest Engine**
- Load historical data (server-side source)
- Run deterministic Backtest Engine
- Generate:
  - `BacktestResult`
  - `CycleStats[]`
  - `RegimeSegments[]`

### 4. **Store Result**
- Write `backtestResults/{jobId}` document
- Include:
  - `backtestResult`
  - `createdAt`
  - `userId`

### 5. **Mark Job as Completed**
- Set `status = "completed"`
- Set `completedAt = now()`

### 6. **Handle Errors**
If any exception occurs:
- Set `status = "failed"`
- Set `errorMessage`
- Do **not** create a result document

---

## 4. Firestore Collections

### `backtestJobs/{jobId}`

Stores job metadata and status.

Fields:
- `jobId`
- `userId`
- `submittedAt`
- `startedAt`
- `completedAt`
- `status`
- `configUsed`
- `engineVersion`
- `priority`
- `errorMessage`

---

### `backtestResults/{jobId}`

Stores completed results.

Fields:
- `jobId`
- `userId`
- `createdAt`
- `backtestResult`

---

## 5. Worker Trigger Model

The worker is triggered by:

### Option A — Firestore `onCreate`
Trigger when a new job is created with `status = "queued"`.

### Option B — Firestore `onUpdate`
Trigger when `status` transitions to `"queued"`.

### Recommended:
**Use `onCreate`** for simplicity.

---

## 6. Worker Execution Environment

The worker must run in a deterministic environment:

- Node.js or Deno (TypeScript)
- Python (optional)
- Dart (via Cloud Run container)

### Recommended:
**Cloud Run container running Dart Backtest Engine**
This allows you to reuse your existing engine code with zero rewrites.

---

## 7. Worker Scaling Model

The worker should support:

- **Parallel execution** (multiple jobs at once)
- **Automatic scaling** (Cloud Run or Functions)
- **Timeout protection**
- **Retry logic** (optional)

### Recommended:
- Cloud Run with concurrency = 1
  (ensures deterministic, isolated runs)
- Autoscaling min = 0, max = N (configurable)

---

## 8. Worker Error Handling

If the worker fails:

- Write `status = "failed"`
- Write `errorMessage`
- Do **not** write a result document
- Do **not** retry automatically (avoid double charges / double runs)

---

## 9. Security Model

### Client can:
- Create jobs for their own userId
- Read their own jobs
- Read their own results

### Client cannot:
- Modify job status
- Modify results
- Access other users' jobs or results

### Worker can:
- Modify any job
- Write results
- Read historical data

---

## 10. Versioning

Each job includes:

- `engineVersion: "1.0.0"`

This allows:

- reproducibility
- migration
- re-running old jobs with new engine versions
- debugging

---

## 11. Cloud Worker Pseudocode

```ts
exports.onBacktestJobCreated = functions.firestore
  .document("backtestJobs/{jobId}")
  .onCreate(async (snap, context) => {
    const job = snap.data();

    try {
      // mark running
      await snap.ref.update({
        status: "running",
        startedAt: new Date(),
      });

      // run engine
      const result = await runBacktestEngine(job.configUsed);

      // write result
      await db.collection("backtestResults").doc(job.jobId).set({
        jobId: job.jobId,
        userId: job.userId,
        createdAt: new Date(),
        backtestResult: result,
      });

      // mark completed
      await snap.ref.update({
        status: "completed",
        completedAt: new Date(),
      });

    } catch (err) {
      await snap.ref.update({
        status: "failed",
        errorMessage: err.message,
      });
    }
  });
```

---

## 12. Summary

The Cloud Worker architecture provides:

- deterministic execution
- scalable job processing
- clean separation of concerns
- reproducible results
- secure user isolation
- compatibility with multi-strategy orchestration

This is the foundation for all remaining Phase 4 features.
