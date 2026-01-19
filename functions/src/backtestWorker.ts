import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { runBacktestEngine } from "./engine";

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

    if (!job) return;

    const userId = job.userId as string | undefined;
    const configUsed = job.configUsed as any | undefined;

    if (!userId || !configUsed) {
      await snap.ref.update({
        status: "failed",
        errorMessage: "Missing userId or configUsed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    try {
      await snap.ref.update({
        status: "running",
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const backtestResult = await runBacktestEngine(configUsed);

      await db.collection("backtestResults").doc(jobId).set({
        jobId,
        userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        backtestResult,
      });

      await snap.ref.update({
        status: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err: any) {
      console.error("Backtest job failed", jobId, err);

      await snap.ref.update({
        status: "failed",
        errorMessage: err?.message ?? "Unknown error",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
