import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { runBacktestEngine, BacktestResult } from "./engine";

const db = admin.firestore();

/**
 * Firestore trigger that runs when a new backtest job is created.
 *
 * Flow:
 * 1. Validate job document
 * 2. Mark job as "running"
 * 3. Call Cloud Run Dart engine
 * 4. Write result to backtestResults collection
 * 5. Mark job as "completed" or "failed"
 */
export const onBacktestJobCreated = functions.firestore
  .document("backtestJobs/{jobId}")
  .onCreate(async (snap, context) => {
    const jobId = context.params.jobId as string;
    const job = snap.data();

    if (!job) {
      console.error(JSON.stringify({
        severity: "ERROR",
        event: "job_invalid",
        jobId,
        message: "Job document is empty",
      }));
      return;
    }

    const userId = job.userId as string | undefined;
    const configUsed = job.configUsed as Record<string, unknown> | undefined;
    const engineVersion = (job.engineVersion as string) ?? "1.0.0";

    // Structured logging: job started
    console.log(JSON.stringify({
      severity: "INFO",
      event: "job_started",
      jobId,
      userId,
      engineVersion,
    }));

    const startTime = Date.now();

    // Validate required fields
    if (!userId || !configUsed) {
      console.error(JSON.stringify({
        severity: "ERROR",
        event: "job_validation_failed",
        jobId,
        message: "Missing userId or configUsed",
      }));

      await snap.ref.update({
        status: "CloudBacktestStatus.failed",
        errorMessage: "Missing userId or configUsed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    try {
      // Mark job as running
      await snap.ref.update({
        status: "CloudBacktestStatus.running",
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Call Cloud Run Dart engine
      const backtestResult: BacktestResult = await runBacktestEngine(configUsed);

      // Check for duplicate result (idempotency)
      const existingResult = await db.collection("backtestResults").doc(jobId).get();
      if (existingResult.exists) {
        console.warn(JSON.stringify({
          severity: "WARNING",
          event: "result_already_exists",
          jobId,
          message: "Result document already exists, skipping write",
        }));
      } else {
        // Write result to backtestResults collection
        await db.collection("backtestResults").doc(jobId).set({
          jobId,
          userId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          backtestResult,
        });
      }

      // Mark job as completed
      await snap.ref.update({
        status: "CloudBacktestStatus.completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const durationMs = Date.now() - startTime;
      console.log(JSON.stringify({
        severity: "INFO",
        event: "job_completed",
        jobId,
        durationMs,
        cyclesCompleted: backtestResult.cyclesCompleted,
        totalReturn: backtestResult.totalReturn,
      }));

    } catch (err: unknown) {
      const durationMs = Date.now() - startTime;
      const errorMessage = err instanceof Error ? err.message : "Unknown error";
      const errorType = err instanceof Error ? err.name : "Error";

      console.error(JSON.stringify({
        severity: "ERROR",
        event: "job_failed",
        jobId,
        errorType,
        message: errorMessage,
        durationMs,
      }));

      await snap.ref.update({
        status: "CloudBacktestStatus.failed",
        errorMessage,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
