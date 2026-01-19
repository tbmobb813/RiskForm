# Cloud Backtesting Worker — TypeScript Skeleton

This skeleton assumes:

- Firestore collections:
  - `backtestJobs/{jobId}`
  - `backtestResults/{jobId}`
- A server-side `runBacktestEngine(config)` function that returns a JSON-serializable `BacktestResult`.

---

## 1. Setup

`functions/package.json` (core deps only):

```json
{
  "name": "riskform-cloud-functions",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^6.0.0"
  },
  "engines": {
    "node": "20"
  }
}
```

`functions/src/index.ts`:

```ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
```

---

## 2. Backtest job worker (Firestore trigger)

```ts
// functions/src/backtestWorker.ts

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { runBacktestEngine } from "./engine"; // you implement this

const db = admin.firestore();

export const onBacktestJobCreated = functions.firestore
  .document("backtestJobs/{jobId}")
  .onCreate(async (snap, context) => {
    const jobId = context.params.jobId as string;
    const job = snap.data();

    if (!job) return;

    try {
      // Basic validation
      if (!job.userId || !job.configUsed) {
        await snap.ref.update({
          status: "failed",
          errorMessage: "Missing userId or configUsed",
        });
        return;
      }

      // Mark as running
      await snap.ref.update({
        status: "running",
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Run engine (deterministic)
      const result = await runBacktestEngine(job.configUsed);

      // Write result
      await db.collection("backtestResults").doc(jobId).set({
        jobId,
        userId: job.userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        backtestResult: result,
      });

      // Mark as completed
      await snap.ref.update({
        status: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err: any) {
      console.error("Backtest job failed", jobId, err);

      await snap.ref.update({
        status: "failed",
        errorMessage: err?.message ?? "Unknown error",
      });
    }
  });
```

---

## 3. Engine bridge (placeholder)

```ts
// functions/src/engine.ts

// TODO: implement using your existing logic or call out to Cloud Run

export async function runBacktestEngine(config: any): Promise<any> {
  // This is a placeholder.
  // In v1, you can reimplement the engine in TS.
  // In v2, you can call a Dart Cloud Run service.
  return {
    // backtestResult JSON shape
  };
}
```

---

## 4. Export in index.ts

```ts
// functions/src/index.ts

export { onBacktestJobCreated } from "./backtestWorker";
```

---

## 5. Deployment

```bash
cd functions
npm install
firebase deploy --only functions
```

This gives you a working skeleton: jobs created in `backtestJobs` trigger the worker, which runs the engine and writes results to `backtestResults`.

---

# Dart Cloud Run Backtest Worker — Skeleton

If you want to reuse your Dart BacktestEngine directly, you can run it in a Cloud Run container and have the TypeScript function call it via HTTP.

---

## 1. Dart HTTP server

`bin/server.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:riskform/services/engines/backtest_engine.dart';
import 'package:riskform/models/backtest/backtest_config.dart';

Future<void> main() async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    int.parse(Platform.environment['PORT'] ?? '8080'),
  );

  print('Server listening on port ${server.port}');

  await for (final request in server) {
    if (request.method == 'POST' && request.uri.path == '/run-backtest') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final jsonBody = json.decode(body) as Map<String, dynamic>;

        final config = BacktestConfig.fromMap(
          jsonBody['configUsed'] as Map<String, dynamic>,
        );

        final engine = BacktestEngine();
        final result = engine.run(config);

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(json.encode({'backtestResult': result.toMap()}));
      } catch (e, st) {
        stderr.writeln('Error: $e\n$st');
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write(json.encode({'error': e.toString()}));
      } finally {
        await request.response.close();
      }
    } else if (request.method == 'GET' && request.uri.path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('OK');
      await request.response.close();
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found');
      await request.response.close();
    }
  }
}
```

---

## 2. Dockerfile

```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080
CMD ["/app/bin/server"]
```

---

## 3. TypeScript worker calling Cloud Run

```ts
// functions/src/engine.ts

import fetch from "node-fetch";

const CLOUD_RUN_URL = process.env.CLOUD_RUN_URL!;

export async function runBacktestEngine(config: any): Promise<any> {
  const res = await fetch(`${CLOUD_RUN_URL}/run-backtest`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ configUsed: config }),
  });

  if (!res.ok) {
    throw new Error(`Cloud Run error: ${res.status}`);
  }

  const json = (await res.json()) as { backtestResult: any };
  return json.backtestResult;
}
```

---

## 4. Cloud Run deployment

```bash
# Build and push
gcloud builds submit --tag gcr.io/PROJECT_ID/backtest-worker

# Deploy
gcloud run deploy backtest-worker \
  --image gcr.io/PROJECT_ID/backtest-worker \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --concurrency 1 \
  --memory 512Mi \
  --timeout 300
```

---

## 5. Set environment variable in Firebase Functions

```bash
firebase functions:config:set backtest.cloud_run_url="https://backtest-worker-xxxxx.run.app"
```

Or use `.env` with Firebase Functions v2.

---

This lets you keep **all engine logic in Dart**, and the TypeScript function becomes a thin orchestration layer.
