# Cloud Worker Implementation (TypeScript + Dart)

This document provides production-ready implementation skeletons for the cloud backtesting worker.

Two options are provided:
- **Option A:** Firebase Functions (TypeScript) — simpler setup
- **Option B:** Cloud Run (Dart) — reuses existing Dart engine code

---

## Option A — Firebase Functions (TypeScript Worker)

This worker:
- Listens for new jobs in `backtestJobs`
- Marks job as running
- Executes the backtest engine
- Writes results to `backtestResults`
- Updates job status

### 1. Project Structure

```
functions/
├── src/
│   ├── index.ts
│   ├── backtestWorker.ts
│   └── engine.ts
├── package.json
└── tsconfig.json
```

### 2. package.json

```json
{
  "name": "riskform-cloud-functions",
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^6.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  },
  "engines": {
    "node": "20"
  }
}
```

### 3. index.ts

```ts
import * as admin from "firebase-admin";

admin.initializeApp();

export { onBacktestJobCreated } from "./backtestWorker";
```

### 4. backtestWorker.ts

```ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { runBacktestEngine } from "./engine";

const db = admin.firestore();

export const onBacktestJobCreated = functions.firestore
  .document("backtestJobs/{jobId}")
  .onCreate(async (snap, context) => {
    const jobId = context.params.jobId;
    const job = snap.data();

    if (!job) return;

    // Structured logging
    console.log(JSON.stringify({
      severity: "INFO",
      event: "job_started",
      jobId,
      userId: job.userId,
      engineVersion: job.engineVersion,
    }));

    const startTime = Date.now();

    try {
      // Validate
      if (!job.userId || !job.configUsed) {
        throw new Error("Missing userId or configUsed");
      }

      // Mark running
      await snap.ref.update({
        status: "running",
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Run engine
      const result = await runBacktestEngine(job.configUsed);

      // Write result
      await db.collection("backtestResults").doc(jobId).set({
        jobId,
        userId: job.userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        backtestResult: result,
      });

      // Mark completed
      await snap.ref.update({
        status: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const durationMs = Date.now() - startTime;
      console.log(JSON.stringify({
        severity: "INFO",
        event: "job_completed",
        jobId,
        durationMs,
        cyclesCompleted: result.cyclesCompleted,
      }));

    } catch (err: any) {
      const durationMs = Date.now() - startTime;
      console.error(JSON.stringify({
        severity: "ERROR",
        event: "job_failed",
        jobId,
        errorType: err.name ?? "Error",
        message: err.message ?? "Unknown error",
        durationMs,
      }));

      await snap.ref.update({
        status: "failed",
        errorMessage: err.message ?? "Unknown error",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
```

### 5. engine.ts (placeholder)

```ts
// TODO: Replace with real implementation or Cloud Run call

export interface BacktestResult {
  totalReturn: number;
  maxDrawdown: number;
  cyclesCompleted: number;
  equityCurve: number[];
  cycles: any[];
  notes: string[];
  engineVersion: string;
}

export async function runBacktestEngine(config: any): Promise<BacktestResult> {
  // Placeholder implementation
  // In production, either:
  // 1. Implement the engine in TypeScript
  // 2. Call out to Cloud Run Dart service

  return {
    totalReturn: 0.12,
    maxDrawdown: -0.08,
    cyclesCompleted: 14,
    equityCurve: [100000, 101000, 102500, 103000],
    cycles: [],
    notes: ["Backtest completed via cloud worker"],
    engineVersion: config.engineVersion ?? "1.0.0",
  };
}
```

### 6. Deployment

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

---

## Option B — Dart Cloud Run Worker (Recommended)

This approach reuses your **existing Dart BacktestEngine** with zero rewrites.

### 1. Project Structure

```
cloud_worker/
├── bin/
│   └── server.dart
├── lib/
│   └── (symlink or copy of your engine code)
├── pubspec.yaml
└── Dockerfile
```

### 2. pubspec.yaml

```yaml
name: riskform_cloud_worker
description: Cloud Run backtest worker

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  # Include your existing engine packages
  # Or reference the main project
```

### 3. server.dart

```dart
import 'dart:convert';
import 'dart:io';

// Import your existing engine
import 'package:riskform/services/engines/backtest_engine.dart';
import 'package:riskform/models/backtest/backtest_config.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  print('Cloud Worker listening on port $port');

  await for (final req in server) {
    await _handleRequest(req);
  }
}

Future<void> _handleRequest(HttpRequest req) async {
  // Health check
  if (req.method == 'GET' && req.uri.path == '/health') {
    req.response
      ..statusCode = HttpStatus.ok
      ..write('OK');
    await req.response.close();
    return;
  }

  // Run backtest
  if (req.method == 'POST' && req.uri.path == '/run-backtest') {
    try {
      final body = await utf8.decoder.bind(req).join();
      final jsonBody = json.decode(body) as Map<String, dynamic>;

      final config = BacktestConfig.fromMap(
        jsonBody['configUsed'] as Map<String, dynamic>,
      );

      final engine = BacktestEngine();
      final result = engine.run(config);

      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode({'backtestResult': result.toMap()}));
    } catch (e, st) {
      stderr.writeln('Error: $e\n$st');
      req.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(json.encode({'error': e.toString()}));
    } finally {
      await req.response.close();
    }
    return;
  }

  // 404
  req.response
    ..statusCode = HttpStatus.notFound
    ..write('Not found');
  await req.response.close();
}
```

### 4. Dockerfile

```dockerfile
# Build stage
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Runtime stage
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080
CMD ["/app/bin/server"]
```

### 5. TypeScript orchestrator calling Cloud Run

Update `functions/src/engine.ts`:

```ts
import fetch from "node-fetch";

const CLOUD_RUN_URL = process.env.CLOUD_RUN_URL!;

export interface BacktestResult {
  totalReturn: number;
  maxDrawdown: number;
  cyclesCompleted: number;
  equityCurve: number[];
  cycles: any[];
  notes: string[];
  engineVersion: string;
}

export async function runBacktestEngine(config: any): Promise<BacktestResult> {
  const res = await fetch(`${CLOUD_RUN_URL}/run-backtest`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ configUsed: config }),
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`Cloud Run error: ${res.status} - ${errorText}`);
  }

  const json = (await res.json()) as { backtestResult: BacktestResult };
  return json.backtestResult;
}
```

### 6. Deploy Cloud Run

```bash
# Build and push
gcloud builds submit --tag gcr.io/PROJECT_ID/riskform-backtest-worker

# Deploy
gcloud run deploy riskform-backtest-worker \
  --image gcr.io/PROJECT_ID/riskform-backtest-worker \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --concurrency 1 \
  --memory 512Mi \
  --timeout 300

# Set environment variable in Firebase Functions
firebase functions:config:set backtest.cloud_run_url="https://riskform-backtest-worker-xxxxx.run.app"
```

---

## Comparison: Firebase Functions vs Cloud Run

| Factor | Firebase Functions | Cloud Run (Dart) |
|--------|-------------------|------------------|
| **Code reuse** | Must rewrite engine in TS | Reuse existing Dart code |
| **Setup complexity** | Simple | Moderate (Docker) |
| **Cold start** | Fast | Slightly slower |
| **Max timeout** | 9 min (gen2) | 60 min |
| **Concurrency** | 1 per instance | Configurable |
| **Cost** | Per invocation | Per request + CPU |
| **Determinism** | High | High |

**Recommendation:** Use Cloud Run (Dart) if you want to reuse your existing engine. Use Firebase Functions (TS) if you prefer simpler deployment and don't mind reimplementing the engine.

---

## Environment Variables

### Firebase Functions
```bash
firebase functions:config:set \
  backtest.cloud_run_url="https://..." \
  backtest.engine_version="1.0.0"
```

### Cloud Run
Set via GCP Console or:
```bash
gcloud run services update riskform-backtest-worker \
  --set-env-vars ENGINE_VERSION=1.0.0
```

---

## Testing Locally

### Firebase Functions Emulator
```bash
cd functions
npm run serve
```

### Cloud Run Local
```bash
cd cloud_worker
dart run bin/server.dart
# Test with curl
curl -X POST http://localhost:8080/run-backtest \
  -H "Content-Type: application/json" \
  -d '{"configUsed": {...}}'
```
