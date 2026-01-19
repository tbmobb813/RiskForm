# Cloud Backtesting Models

## CloudBacktestJob

Represents a submitted backtest job.

Fields:
- `jobId: string`
- `userId: string`
- `submittedAt: Timestamp`
- `startedAt: Timestamp | null`
- `completedAt: Timestamp | null`
- `status: "queued" | "running" | "completed" | "failed"`
- `configUsed: BacktestConfig` (snapshot)
- `engineVersion: string`
- `priority: number` (optional)
- `errorMessage: string | null`

## CloudBacktestResult

Represents the result of a completed backtest job.

Fields:
- `jobId: string`
- `userId: string`
- `createdAt: Timestamp`
- `backtestResult: BacktestResult` (serialized)
