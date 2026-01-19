# RiskForm Cloud Functions

Firebase Cloud Functions for the RiskForm cloud backtesting pipeline.

## Architecture

```
Flutter App
    ↓ (submit job)
Firestore: backtestJobs/{jobId}
    ↓ (onCreate trigger)
Firebase Function: onBacktestJobCreated
    ↓ (HTTP call)
Cloud Run: Dart BacktestEngine
    ↓ (return result)
Firebase Function
    ↓ (write result)
Firestore: backtestResults/{jobId}
    ↓ (realtime stream)
Flutter App
```

## Setup

### 1. Install dependencies

```bash
cd functions
npm install
```

### 2. Configure Cloud Run URL

After deploying the Dart Cloud Run service, set the URL:

```bash
firebase functions:config:set backtest.cloud_run_url="https://riskform-backtest-worker-xxxxx.run.app"
```

### 3. Build TypeScript

```bash
npm run build
```

### 4. Deploy

```bash
npm run deploy
# or
firebase deploy --only functions
```

## Local Development

### Run emulator

```bash
npm run serve
```

This starts the Firebase emulator with Functions and Firestore.

### View logs

```bash
npm run logs
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `backtest.cloud_run_url` | URL of the Cloud Run Dart engine service |

Set via:
```bash
firebase functions:config:set backtest.cloud_run_url="https://..."
```

## Firestore Collections

### backtestJobs

| Field | Type | Description |
|-------|------|-------------|
| jobId | string | Unique job identifier |
| userId | string | User who submitted the job |
| status | string | queued, running, completed, failed |
| configUsed | map | BacktestConfig as JSON |
| engineVersion | string | Engine version to use |
| submittedAt | timestamp | When job was submitted |
| startedAt | timestamp | When job started running |
| completedAt | timestamp | When job finished |
| errorMessage | string | Error message if failed |

### backtestResults

| Field | Type | Description |
|-------|------|-------------|
| jobId | string | Reference to job |
| userId | string | User who owns the result |
| createdAt | timestamp | When result was written |
| backtestResult | map | Full BacktestResult as JSON |

## Troubleshooting

### Function not triggering

1. Check Firestore rules allow the client to create jobs
2. Verify the job document has `status: "CloudBacktestStatus.queued"`
3. Check function logs for errors

### Cloud Run call failing

1. Verify `backtest.cloud_run_url` is set correctly
2. Check Cloud Run service is deployed and healthy
3. Verify Cloud Run allows unauthenticated access (or configure auth)

### Duplicate results

The worker checks for existing results before writing. If you see warnings about duplicates, the function may have been triggered multiple times (rare but possible).
