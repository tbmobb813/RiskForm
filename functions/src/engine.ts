import * as functions from "firebase-functions";
import fetch from "node-fetch";

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
 * Get Cloud Run URL from Firebase Functions config.
 *
 * Set via: firebase functions:config:set backtest.cloud_run_url="https://..."
 */
function getCloudRunUrl(): string {
  const config = functions.config();
  const url = config.backtest?.cloud_run_url;

  if (!url) {
    throw new Error(
      "CLOUD_RUN_URL not configured. " +
      "Run: firebase functions:config:set backtest.cloud_run_url=\"https://your-service.run.app\""
    );
  }

  return url as string;
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
  const cloudRunUrl = getCloudRunUrl();
  const endpoint = `${cloudRunUrl}/run-backtest`;

  console.log(JSON.stringify({
    severity: "INFO",
    event: "engine_call_started",
    endpoint,
  }));

  const startTime = Date.now();

  const response = await fetch(endpoint, {
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

  const json = await response.json() as { backtestResult: BacktestResult };

  console.log(JSON.stringify({
    severity: "INFO",
    event: "engine_call_completed",
    durationMs,
    cyclesCompleted: json.backtestResult.cyclesCompleted,
  }));

  return json.backtestResult;
}
