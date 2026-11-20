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

## Live option data (Tradier)

`getOptionChain` is a callable function that loads a stock price and option
chains from Tradier for the signed-in user. The Tradier token stays on the
server.

### Set up

1. Get a token from your Tradier account's API settings (use the sandbox
   token for the sandbox).
2. Store it as a secret. Never put it in a `.env` file, which is tracked by git:

   ```bash
   firebase functions:secrets:set TRADIER_TOKEN
   ```

3. Choose who may use it. Tradier market data is licensed for the account
   holder, so access is **denied to everyone** until you list UIDs. Find a UID
   in the Firebase console under Authentication. Set these in
   `functions/.env.<project-id>` or answer the prompts at deploy:

   ```
   TRADIER_ALLOWED_UIDS=uid1,uid2
   TRADIER_ENV=production   # or sandbox (delayed data)
   ```

4. Deploy: `firebase deploy --only functions:getOptionChain`

### Behavior

- Requires sign-in, then the allow-list, then input checks.
- 30 requests per user per hour, counted in the `tradierUsage` collection.
  Repeat requests for the same symbol and range within 60 seconds are served
  from memory and do not count.
- One request uses 2 Tradier calls plus one per expiration (at most 8).
  Tradier allows 120 market data requests per minute per token in production
  (60 in the sandbox). Tradier reports an exceeded limit as HTTP 400 with the
  text `Quota Violation`, which the client detects.
- Greeks and implied volatility come from Tradier's feed and may be hourly.

### Test

```bash
npm run test:unit
```

These tests use a fake `fetch` and need no emulator or token.

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

### tradierUsage

| Field | Type | Description |
|-------|------|-------------|
| uid | string | User who made the requests |
| hour | number | Hours since the Unix epoch (the quota window) |
| count | number | Requests counted in that hour |

Written only by the function. Client access stays denied by the Firestore
rules.

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
