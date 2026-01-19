import { defineString } from "firebase-functions/params";

// Use the global fetch available in Node 18+ rather than depending on node-fetch
declare const fetch: typeof globalThis.fetch;

// Define the Cloud Run URL as a Firebase parameter (for params API migration)
// This can be set via environment variable or Firebase parameter configuration.
const cloudRunUrlParam = defineString("backtest.cloud_run_url", {
  description: "URL of the Cloud Run backtest worker service",
});

// Resolve the Cloud Run URL with fallbacks:
// 1. `process.env.CLOUD_RUN_URL` (local testing / env var)
// 2. Firebase Functions Params (`backtest.cloud_run_url`)
// 3. empty string (caller will handle/error)
function resolveCloudRunUrl(): { url: string; source: "env" | "params" | "none" } {
  if (process.env.CLOUD_RUN_URL) {
    return { url: process.env.CLOUD_RUN_URL, source: "env" };
  }

  try {
    // `value()` is available when params are configured; guard in case it's absent.
    if (cloudRunUrlParam && typeof (cloudRunUrlParam as any).value === "function") {
      const v = (cloudRunUrlParam as any).value();
      if (v) return { url: v as string, source: "params" };
    }
  } catch (_) {
    // ignore and fall through
  }

  return { url: "", source: "none" };
}

/**
 * Backtest result structure returned from Cloud Run Dart engine.
 * Must match the Dart BacktestResult.toMap() output.
 */
export interface BacktestResult {
  configUsed: Record<string, unknown>;
  equityCurve: number[];
  maxDrawdown: number;
  totalReturn: number;
  cyclesCompleted: number;
  notes: string[];
  cycles: CycleStats[];
  avgCycleReturn: number;
  avgCycleDurationDays: number;
  assignmentRate: number;
  uptrendAvgCycleReturn: number;
  downtrendAvgCycleReturn: number;
  sidewaysAvgCycleReturn: number;
  uptrendAssignmentRate: number;
  downtrendAssignmentRate: number;
  sidewaysAssignmentRate: number;
  engineVersion: string;
  regimeSegments: RegimeSegment[];
}

export interface CycleStats {
  cycleId: string;
  index: number;
  startEquity: number;
  endEquity: number;
  durationDays: number;
  hadAssignment: boolean;
  outcome: string | null;
  dominantRegime: string | null;
  startIndex: number | null;
  endIndex: number | null;
  assignmentPrice: number | null;
  assignmentStrike: number | null;
  calledAwayPrice: number | null;
  calledAwayStrike: number | null;
}

export interface RegimeSegment {
  regime: string;
  startDate: string;
  endDate: string;
  startIndex: number;
  endIndex: number;
}

/**
 * Call the Cloud Run Dart backtest engine.
 *
 * @param configUsed - The BacktestConfig as a JSON-serializable map
 * @returns The BacktestResult from the Dart engine
 */
export async function runBacktestEngine(
  configUsed: Record<string, unknown>
): Promise<BacktestResult> {
  const resolved = resolveCloudRunUrl();
  const cloudRunUrl = resolved.url;
  // Log which source provided the Cloud Run URL to aid debugging
  console.info(`Cloud Run URL source: ${resolved.source}`);
  if (!cloudRunUrl) {
    throw new Error("Cloud Run URL is not configured. Set CLOUD_RUN_URL env var or Functions params 'backtest.cloud_run_url'.");
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

  const json = await res.json() as { backtestResult: BacktestResult };

  return json.backtestResult;
}
