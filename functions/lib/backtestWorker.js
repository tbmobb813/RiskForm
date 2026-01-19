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
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const engine_1 = require("./engine");
// Get Firestore instance (admin is initialized in index.ts)
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
exports.onBacktestJobCreated = (0, firestore_1.onDocumentCreated)("backtestJobs/{jobId}", async (event) => {
    var _a;
    const snap = event.data;
    if (!snap)
        return;
    const jobId = event.params.jobId;
    const job = snap.data();
    if (!job)
        return;
    const userId = job.userId;
    const configUsed = job.configUsed;
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
        const backtestResult = await (0, engine_1.runBacktestEngine)(configUsed);
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
    }
    catch (err) {
        console.error("Backtest job failed", jobId, err);
        await snap.ref.update({
            status: "failed",
            errorMessage: (_a = err === null || err === void 0 ? void 0 : err.message) !== null && _a !== void 0 ? _a : "Unknown error",
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
});
//# sourceMappingURL=backtestWorker.js.map