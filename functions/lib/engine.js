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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.runBacktestEngine = runBacktestEngine;
const functions = __importStar(require("firebase-functions"));
const node_fetch_1 = __importDefault(require("node-fetch"));
/**
 * Get Cloud Run URL from Firebase Functions config.
 *
 * Set via: firebase functions:config:set backtest.cloud_run_url="https://..."
 */
function getCloudRunUrl() {
    const config = functions.config();
    const url = config.backtest?.cloud_run_url;
    if (!url) {
        throw new Error("CLOUD_RUN_URL not configured. " +
            "Run: firebase functions:config:set backtest.cloud_run_url=\"https://your-service.run.app\"");
    }
    return url;
}
/**
 * Call the Cloud Run Dart backtest engine.
 *
 * @param configUsed - The BacktestConfig as a JSON-serializable map
 * @returns The BacktestResult from the Dart engine
 */
async function runBacktestEngine(configUsed) {
    const cloudRunUrl = getCloudRunUrl();
    const endpoint = `${cloudRunUrl}/run-backtest`;
    console.log(JSON.stringify({
        severity: "INFO",
        event: "engine_call_started",
        endpoint,
    }));
    const startTime = Date.now();
    const response = await (0, node_fetch_1.default)(endpoint, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ configUsed }),
    });
    const durationMs = Date.now() - startTime;
    if (!response.ok) {
        const errorText = await response.text();
        console.error(JSON.stringify({
            severity: "ERROR",
            event: "engine_call_failed",
            statusCode: response.status,
            errorText,
            durationMs,
        }));
        throw new Error(`Cloud Run error ${response.status}: ${errorText}`);
    }
    const json = await response.json();
    console.log(JSON.stringify({
        severity: "INFO",
        event: "engine_call_completed",
        durationMs,
        cyclesCompleted: json.backtestResult.cyclesCompleted,
    }));
    return json.backtestResult;
}
//# sourceMappingURL=engine.js.map