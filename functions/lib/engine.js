"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runBacktestEngine = runBacktestEngine;
const params_1 = require("firebase-functions/params");
// Define the Cloud Run URL as a Firebase parameter
// This can be set via environment variable or Firebase parameter configuration
const cloudRunUrlParam = (0, params_1.defineString)("CLOUD_RUN_URL", {
    description: "URL of the Cloud Run backtest worker service",
});
/**
 * Call the Cloud Run Dart backtest engine.
 *
 * @param configUsed - The BacktestConfig as a JSON-serializable map
 * @returns The BacktestResult from the Dart engine
 */
async function runBacktestEngine(configUsed) {
    const cloudRunUrl = cloudRunUrlParam.value();
    const res = await fetch(`${cloudRunUrl}/run-backtest`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ configUsed }),
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`Cloud Run error ${res.status}: ${text}`);
    }
    const json = await res.json();
    return json.backtestResult;
}
//# sourceMappingURL=engine.js.map