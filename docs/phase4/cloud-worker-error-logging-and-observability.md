# Cloud Worker Error Logging & Observability

This document defines how the Cloud Backtesting Worker logs errors, exposes operational insights, and provides observability into job execution.
The goal is to ensure that every cloud backtest job is traceable, debuggable, and auditable.

---

## 1. Goals

- Capture all worker errors with full context.
- Provide structured logs for easy filtering.
- Track job lifecycle events.
- Enable debugging of failed jobs.
- Provide metrics for performance and reliability.
- Support alerting for critical failures.
- Maintain user privacy and isolation.

---

## 2. Logging Principles

### 2.1 Logs must be structured
Every log entry should be a JSON object with fields like:

```json
{
  "severity": "ERROR",
  "jobId": "abc123",
  "userId": "uid123",
  "engineVersion": "1.0.0",
  "event": "backtest_failed",
  "message": "Assignment model threw exception",
  "stack": "stack trace here"
}
```

Structured logs allow:

- filtering by jobId
- filtering by userId
- filtering by severity
- grouping by engineVersion

---

### 2.2 Logs must never contain:
- PII
- user configs
- raw historical data
- sensitive financial information

Only metadata and error context.

---

## 3. Error Classification

Errors fall into three categories:

### 3.1 Transient Errors
- network timeouts
- Firestore write failures
- Cloud Run cold starts
- temporary resource exhaustion

**Action:** log as `WARNING`, mark job as `failed`.

### 3.2 Permanent Errors
- invalid BacktestConfig
- unsupported engineVersion
- corrupted job document
- missing fields

**Action:** log as `ERROR`, mark job as `failed`.

### 3.3 Engine Errors
- exceptions thrown inside BacktestEngine
- invalid lifecycle transitions
- division by zero
- unexpected NaN values

**Action:** log as `CRITICAL`, mark job as `failed`.

---

## 4. Worker Logging Structure

### 4.1 Job Start Log

```json
{
  "severity": "INFO",
  "event": "job_started",
  "jobId": "abc123",
  "userId": "uid123",
  "engineVersion": "1.0.0"
}
```

### 4.2 Job Completed Log

```json
{
  "severity": "INFO",
  "event": "job_completed",
  "jobId": "abc123",
  "durationMs": 4821,
  "cyclesCompleted": 14
}
```

### 4.3 Job Failed Log

```json
{
  "severity": "ERROR",
  "event": "job_failed",
  "jobId": "abc123",
  "errorType": "EngineError",
  "message": "Cycle duration negative",
  "stack": "stack trace..."
}
```

---

## 5. Firestore Error Reporting

When a job fails, the worker writes:

```json
{
  "status": "failed",
  "errorMessage": "Cycle duration negative",
  "completedAt": "<timestamp>"
}
```

This allows the client to:

- show failure state
- allow user to resubmit
- display error context

---

## 6. Cloud Logging Integration

All logs should be sent to:

- **Google Cloud Logging** (if using Cloud Run or Firebase Functions)
- Log-based metrics can be created for:
  - job failures
  - engine errors
  - average job duration
  - job throughput

---

## 7. Metrics & Dashboards

Recommended metrics:

### 7.1 Job Metrics
- jobs per minute
- jobs completed
- jobs failed
- job duration (p50, p90, p99)
- job queue latency

### 7.2 Engine Metrics
- average cycles per job
- average runtime per cycle
- failure rate per engineVersion

### 7.3 Worker Metrics
- CPU usage
- memory usage
- cold starts
- concurrency

### 7.4 Dashboard
Create a Cloud Monitoring dashboard with:

- Job success/failure chart
- Job duration histogram
- Worker CPU/memory
- Error logs filtered by severity

---

## 8. Alerting

Recommended alerts:

### 8.1 High Failure Rate
Trigger if:
- `job_failed` logs exceed threshold
- e.g., > 5 failures in 5 minutes

### 8.2 Worker Crashes
Trigger if:
- Cloud Run container exits unexpectedly
- Cloud Function errors spike

### 8.3 Slow Jobs
Trigger if:
- p99 job duration > threshold (e.g., 30 seconds)

### 8.4 No Jobs Processed
Trigger if:
- no `job_completed` logs for > 10 minutes
- indicates worker outage

---

## 9. Traceability

Every job should be traceable end-to-end using:

- `jobId`
- `userId`
- `engineVersion`
- timestamps:
  - `submittedAt`
  - `startedAt`
  - `completedAt`

This allows:

- debugging
- performance analysis
- reproducibility
- audit trails

---

## 10. Summary

This observability system ensures:

- every job is logged
- every failure is captured
- every result is traceable
- performance is measurable
- alerts catch issues early
- debugging is straightforward

This is the operational backbone of the cloud backtesting pipeline.
