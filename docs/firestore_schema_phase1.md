# Firestore Schema — Phase 1

Goal: keep a single, simple, durable and scalable collection layout for Phase 1.

Overview
- Top-level collection per user (under `users/{uid}/trade_plans`) — a small, logical partition keyed by owner.

- Each document represents a single saved trade plan.

Collection

- Path: `users/{uid}/trade_plans/{planId}`

Document fields
- `strategyId` (string) — canonical id for the strategy (e.g. `csp`, `cc`, `credit_spread`).
- `strategyName` (string) — human-friendly name.
- `inputs` (map) — `TradeInputs.toJson()` shape; numeric fields stored as numbers; `expiration` as ISO string or Firestore Timestamp.
- `payoff` (map) — keys: `maxGain`, `maxLoss`, `breakeven`, `capitalRequired` (numbers).
- `risk` (map) — keys: `riskPercentOfAccount` (number), `assignmentExposure` (bool), `capitalLocked` (number), `warnings` (array of string).
- `notes` (string) — optional notes.
- `tags` (array of string) — optional tags for filtering.
- `createdAt` (timestamp) — when the plan was created (client or server timestamp).
- `updatedAt` (timestamp) — when the plan was last updated (server timestamp recommended).

Design notes
- Using `users/{uid}/trade_plans` keeps documents partitioned by user and avoids per-app document bloat.
- Storing `inputs`, `payoff`, and `risk` as maps keeps related data together and makes reads cheap for a plan overview.
- `updatedAt` should be written with `FieldValue.serverTimestamp()` to ensure consistency.

Indexes / Queries
- Typical queries:
  - List plans for a user ordered by `createdAt` or `updatedAt` (create an index on `createdAt` or `updatedAt` as needed).
  - Filter by `tags` or `strategyId` (array-contains on `tags`; index `strategyId` if filtering frequently).

Security rules (excerpt)
```
match /users/{userId}/trade_plans/{planId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

Example document (JSON)
```
{
  "strategyId": "csp",
  "strategyName": "Cash Secured Put",
  "inputs": {
     "strike": 50.0,
     "premiumReceived": 2.0,
     "underlyingPrice": 55.0
  },
  "payoff": {
     "maxGain": 200.0,
     "maxLoss": 4800.0,
     "breakeven": 48.0,
     "capitalRequired": 5000.0
  },
  "risk": {
     "riskPercentOfAccount": 50.0,
     "assignmentExposure": true,
     "capitalLocked": 5000.0,
     "warnings": ["locks more than 10% of account"]
  },
  "notes": "Example plan",
  "tags": ["income","wheel"],
  "createdAt": {"_seconds": 1670000000, "_nanoseconds": 0},
  "updatedAt": {"_seconds": 1670000000, "_nanoseconds": 0}
}
```

Migration & versioning
- If schema changes in the future, add a `schemaVersion` field to documents to migrate safely.

Operational
- Backups: export Firestore periodically or rely on managed export.
- Monitoring: add alerts for high write or read rates per user.
