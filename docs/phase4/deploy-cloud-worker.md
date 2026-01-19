
# Phase 4 — Deploying Cloud Run Worker + Firebase Functions Orchestrator

This guide walks through deploying:

1. Dart Cloud Run worker (`/run-backtest`)
2. Firebase Functions (TypeScript) Firestore trigger
3. Wiring them together via `CLOUD_RUN_URL`
4. Running an end-to-end cloud backtest

---

## 1. Prerequisites

- gcloud CLI installed and authenticated
- Firebase CLI installed and authenticated
- GCP project created and linked to Firebase
- Dart SDK installed
- Your Dart BacktestEngine and BacktestConfig already implemented

---

## 2. Deploy Dart Cloud Run Worker

### 2.1 Project structure

The Dart worker lives in `/cloud_worker`:

```
cloud_worker/
├── bin/
│   └── server.dart    # HTTP entrypoint
├── pubspec.yaml
├── Dockerfile
└── .dockerignore
```

`bin/server.dart` handles:

- Listen on `PORT` env var (default 8080)
- `GET /health` - Health check
- `POST /run-backtest` - Execute backtest
  - Accept `{ configUsed: BacktestConfigJson }`
  - Return `{ backtestResult: BacktestResultJson }`

### 2.2 Dockerfile

The Dockerfile in `/cloud_worker`:

```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:stable-slim
WORKDIR /app
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/server

ENV PORT=8080
EXPOSE 8080

CMD ["/app/server"]
```

### 2.3 Build and deploy to Cloud Run

```bash
# Set your project
PROJECT_ID=<your-project-id>
SERVICE_NAME=riskform-backtest-worker
REGION=us-central1

gcloud config set project $PROJECT_ID

# Navigate to cloud_worker directory
cd cloud_worker

# Build container image
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

# Deploy to Cloud Run
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --concurrency 1 \
  --memory 512Mi \
  --timeout 300
```

### 2.4 Get the Cloud Run URL

After deploy, note the Cloud Run URL:

```bash
gcloud run services describe $SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --format="value(status.url)"
```

Example output: `https://riskform-backtest-worker-abc123-uc.a.run.app`

### 2.5 Verify deployment

```bash
# Health check
curl https://riskform-backtest-worker-abc123-uc.a.run.app/health

# Test backtest (placeholder result)
curl -X POST https://riskform-backtest-worker-abc123-uc.a.run.app/run-backtest \
  -H "Content-Type: application/json" \
  -d '{"configUsed": {"symbol": "AAPL", "strategyId": "wheel", "startingCapital": 100000}}'
```

---

## 3. Deploy Firebase Functions Orchestrator

### 3.1 Project structure

The Functions live in `/functions`:

```
functions/
├── src/
│   ├── index.ts           # Entry point
│   ├── backtestWorker.ts  # Firestore trigger
│   └── engine.ts          # Cloud Run bridge
├── package.json
├── tsconfig.json
└── .eslintrc.js
```

### 3.2 Install dependencies

```bash
cd functions
npm install
```

### 3.3 Configure CLOUD_RUN_URL

Set the Cloud Run URL in Functions config:

```bash
firebase functions:config:set backtest.cloud_run_url="https://riskform-backtest-worker-abc123-uc.a.run.app"
```

Verify the config:

```bash
firebase functions:config:get
```

### 3.4 Build and deploy Functions

```bash
# Build TypeScript
npm run build

# Deploy
npm run deploy
# or
firebase deploy --only functions
```

---

## 4. Deploy Firestore Security Rules

Ensure your Firestore rules are deployed:

```bash
firebase deploy --only firestore:rules
```

The rules in `firestore.rules` should match the spec in `/docs/phase4/firestore-security-rules.md`.

---

## 5. Deploy Firestore Indexes

Create the required composite index for `watchUserJobs`:

**Option A: Firebase Console**

Go to Firestore → Indexes → Add Index:
- Collection: `backtestJobs`
- Fields: `userId` (Ascending), `submittedAt` (Descending)

**Option B: firestore.indexes.json**

Create `firestore.indexes.json` in project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "backtestJobs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "submittedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

Deploy:

```bash
firebase deploy --only firestore:indexes
```

---

## 6. End-to-End Test

### 6.1 Pre-checks

- [ ] Cloud Run worker deployed and `/health` returns OK
- [ ] Firebase Functions deployed
- [ ] `backtest.cloud_run_url` config set
- [ ] Firestore rules deployed
- [ ] Firestore indexes deployed
- [ ] Flutter app has CloudBacktestService pointing to correct collections

### 6.2 Test flow

1. **Open the app**, configure a backtest (symbol, strategy, dates).

2. **Tap "Run in Cloud"** button.

3. **Check Firestore** (Firebase Console):
   - New document in `backtestJobs` with `status = "CloudBacktestStatus.queued"`

4. **Watch Cloud Logging** (GCP Console → Logging):
   - Filter: `resource.type="cloud_function"`
   - Look for:
     - `job_started`
     - `engine_call_started`
     - `engine_call_completed`
     - `job_completed` or `job_failed`

5. **Check Firestore again**:
   - `backtestJobs/{jobId}.status` → `"CloudBacktestStatus.completed"` or `"CloudBacktestStatus.failed"`
   - `backtestResults/{jobId}` document created (if completed)

6. **In the app**:
   - CloudJobStatusScreen shows live status updates
   - When completed, "View Full Results" button appears
   - Tap to open CloudBacktestResultScreen
   - Dashboard shows cloud results when "Cloud" or "Both" toggle selected

### 6.3 Troubleshooting

| Symptom | Check |
|---------|-------|
| Job stays `queued` | Function not triggering - check deployment, check rules |
| Job goes to `failed` immediately | Check function logs for validation errors |
| Cloud Run error | Check `backtest.cloud_run_url` config, check Cloud Run logs |
| Result not appearing | Check function completed, check Firestore rules for results |
| App not updating | Check Firestore streams, check Flutter console for errors |

---

## 7. Production Hardening

### 7.1 Cloud Run authentication (recommended)

Instead of `--allow-unauthenticated`, use IAM:

```bash
# Deploy without public access
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated

# Grant Functions service account access
gcloud run services add-iam-policy-binding $SERVICE_NAME \
  --region $REGION \
  --member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" \
  --role="roles/run.invoker"
```

Update `engine.ts` to use identity tokens for authenticated calls.

### 7.2 Monitoring and alerting

Set up Cloud Monitoring alerts for:

- Function error rate > 5%
- Function execution time p99 > 30s
- Cloud Run error rate > 5%
- Cloud Run request latency p99 > 60s

### 7.3 Cost controls

- Set Cloud Run max instances to limit concurrent backtests
- Set up billing alerts
- Consider Cloud Run min instances = 0 for cost savings (accepts cold start latency)

---

## 8. Completion Checklist

Phase 4 is complete when:

- [ ] Cloud Run worker deployed and reachable
- [ ] Firebase Functions orchestrator deployed
- [ ] `CLOUD_RUN_URL` config set correctly
- [ ] Firestore rules deployed
- [ ] Firestore indexes deployed
- [ ] Jobs move from `queued` → `running` → `completed/failed`
- [ ] Results are written to `backtestResults`
- [ ] CloudJobStatusScreen shows status correctly
- [ ] CloudBacktestResultScreen renders results correctly
- [ ] CloudBacktestHistoryScreen lists jobs
- [ ] Dashboard toggle shows cloud results
- [ ] End-to-end test passes

At that point, all core Phase 4 requirements are satisfied.

---

## 9. Next Steps (Phase 4B - Optional)

- [ ] Local vs cloud result validator (same config, compare outputs)
- [ ] Cloud backtest comparison (multi-run side-by-side)
- [ ] Cloud backtest filters (symbol, date range, status)
- [ ] Re-run failed jobs
- [ ] Job tags and labels
- [ ] Batch job submission
