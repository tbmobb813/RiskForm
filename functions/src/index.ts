/**
 * RiskForm Cloud Functions
 *
 * Entry point for Firebase Cloud Functions.
 * Exports the Firestore trigger for cloud backtesting.
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export cloud functions
export { onBacktestJobCreated } from "./backtestWorker";
