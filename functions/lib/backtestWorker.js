"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onBacktestJobCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const engine_1 = require("./engine");
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
exports.onBacktestJobCreated = functions.firestore
    .document("backtestJobs/{jobId}")
    .onCreate(async (snap, context) => {
    const jobId = context.params.jobId;
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
    const userId = job.userId;
    const configUsed = job.configUsed;
    const engineVersion = job.engineVersion ?? "1.0.0";
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
        const backtestResult = await (0, engine_1.runBacktestEngine)(configUsed);
        // Check for duplicate result (idempotency)
        const existingResult = await db.collection("backtestResults").doc(jobId).get();
        if (existingResult.exists) {
            console.warn(JSON.stringify({
                severity: "WARNING",
                event: "result_already_exists",
                jobId,
                message: "Result document already exists, skipping write",
            }));
        }
        else {
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
    }
    catch (err) {
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
//# sourceMappingURL=backtestWorker.js.map