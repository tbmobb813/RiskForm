"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runBacktestEngine = runBacktestEngine;
const params_1 = require("firebase-functions/params");
// Define the Cloud Run URL as a Firebase parameter (for params API migration).
// Param names must follow env-var style: uppercase letters, digits, and underscores.
// Use `BACKTEST_CLOUD_RUN_URL` so the deployer can set it via params or it maps cleanly
// to an environment variable.
const cloudRunUrlParam = (0, params_1.defineString)("BACKTEST_CLOUD_RUN_URL", {
    description: "URL of the Cloud Run backtest worker service",
});
// Resolve the Cloud Run URL with fallbacks:
// 1. `process.env.CLOUD_RUN_URL` (local testing / env var)
// 2. Firebase Functions Params (`backtest.cloud_run_url`)
// 3. empty string (caller will handle/error)
function resolveCloudRunUrl() {
    if (process.env.CLOUD_RUN_URL) {
        return { url: process.env.CLOUD_RUN_URL, source: "env" };
    }
    try {
        // `value()` is available when params are configured; guard in case it's absent.
        if (cloudRunUrlParam && typeof cloudRunUrlParam.value === "function") {
            const v = cloudRunUrlParam.value();
            if (v)
                return { url: v, source: "params" };
        }
    }
    catch (_) {
        // ignore and fall through
    }
    return { url: "", source: "none" };
}
/**
 * Call the Cloud Run Dart backtest engine.
 *
 * @param configUsed - The BacktestConfig as a JSON-serializable map
 * @returns The BacktestResult from the Dart engine
 */
async function runBacktestEngine(configUsed) {
    const resolved = resolveCloudRunUrl();
    const cloudRunUrl = resolved.url;
    // Log which source provided the Cloud Run URL to aid debugging
    console.info(`Cloud Run URL source: ${resolved.source}`);
    if (!cloudRunUrl) {
        throw new Error("Cloud Run URL is not configured. Set CLOUD_RUN_URL env var or Functions params 'BACKTEST_CLOUD_RUN_URL'.");
    }
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