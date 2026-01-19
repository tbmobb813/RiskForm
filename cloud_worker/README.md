# RiskForm Cloud Worker

Dart Cloud Run service that runs the BacktestEngine for cloud backtesting.

## Architecture

This service receives backtest requests from Firebase Functions and executes the Dart BacktestEngine, returning results via HTTP.

## Endpoints

### GET /health

Health check endpoint.

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0"
}
```

### POST /run-backtest

Execute a backtest with the provided configuration.

**Request:**

```json
{
  "configUsed": {
    "symbol": "AAPL",
    "strategyId": "wheel",
    "startingCapital": 100000,
    "maxCycles": 50,
    "startDate": "2023-01-01",
    "endDate": "2024-01-01"
  }
}
```

**Response:**

```json
{
  "backtestResult": {
    "totalReturn": 0.12,
    "maxDrawdown": -0.08,
    "cyclesCompleted": 14,
    "equityCurve": [100000, 101000, ...],
    "cycles": [...],
    "engineVersion": "1.0.0"
  }
}
```

## Local Development

### Run locally

```bash
cd cloud_worker
dart pub get
dart run bin/server.dart
```

Server starts on port 8080 (or PORT env var).

### Test locally

```bash
# Health check
curl http://localhost:8080/health

# Run backtest
curl -X POST http://localhost:8080/run-backtest \
  -H "Content-Type: application/json" \
  -d '{"configUsed": {"symbol": "AAPL", "strategyId": "wheel", "startingCapital": 100000}}'
```

## Deployment

### 1. Build and push container

```bash
cd cloud_worker
gcloud builds submit --tag gcr.io/PROJECT_ID/riskform-backtest-worker
```

### 2. Deploy to Cloud Run

```bash
gcloud run deploy riskform-backtest-worker \
  --image gcr.io/PROJECT_ID/riskform-backtest-worker \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --concurrency 1 \
  --memory 512Mi \
  --timeout 300
```

### 3. Get service URL

```bash
gcloud run services describe riskform-backtest-worker \
  --platform managed \
  --region us-central1 \
  --format="value(status.url)"
```

### 4. Configure Firebase Functions

```bash
firebase functions:config:set backtest.cloud_run_url="https://riskform-backtest-worker-xxxxx.run.app"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| PORT     | 8080    | Server port |

### Cloud Run Settings

| Setting | Recommended | Description |
| --------- | ------------- | ------------- |
| Memory | 512Mi-1Gi | Depends on backtest complexity |
| CPU | 1 | Usually sufficient |
| Concurrency | 1 | One backtest per instance |
| Timeout | 300s | Max backtest duration |
| Min instances | 0 | Scale to zero when idle |
| Max instances | 10 | Limit concurrent backtests |

## Engine

The cloud worker includes a pure-Dart implementation of the wheel strategy backtest engine
(`lib/backtest_engine.dart`). This mirrors the core logic from the main Flutter app but
without Flutter dependencies, making it suitable for server-side execution.

The engine simulates:

- Cash-secured put (CSP) selling at ATM strikes
- Assignment handling when puts expire ITM
- Covered call (CC) selling at 2% OTM strikes
- Called-away handling when calls expire ITM
- Full cycle tracking with metrics calculation

## Logging

All logs are structured JSON for Cloud Logging compatibility:

```json
{
  "severity": "INFO",
  "event": "backtest_completed",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "durationMs": 4821,
  "cyclesCompleted": 14
}
```

Filter in Cloud Logging:

resource.type="cloud_run_revision"
jsonPayload.event="backtest_completed"
