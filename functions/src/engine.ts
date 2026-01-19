import * as functions from "firebase-functions";

// Use the global fetch available in Node 18+ rather than depending on node-fetch
declare const fetch: any;

const CLOUD_RUN_URL = (functions.config() as any)?.backtest?.cloud_run_url as string;

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
  const res = await fetch(`${CLOUD_RUN_URL}/run-backtest`, {
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
