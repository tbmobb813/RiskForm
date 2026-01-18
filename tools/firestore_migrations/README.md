Fix wheel cycle state migration

This small migration scans `users/*/wheel/cycle` documents and fixes invalid `state` values
that could cause runtime errors (out-of-range enum indices).

Prerequisites
- Node 18+ (or recent Node with global `fetch`), or adjust the script to include a fetch polyfill.
- A Firebase service account JSON with Firestore access.

Instructions

1. Copy your service account JSON path into `GOOGLE_APPLICATION_CREDENTIALS`:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"
```

2. Install dependencies:

```bash
cd tools/firestore_migrations
npm install
```

3. (Optional) Configure telemetry by setting `TELEMETRY_URL` to an ingestion endpoint.

4. Run the script:

```bash
node fix_wheel_cycle_state.js
```

Dry-run mode

You can run the script in dry-run mode which will report proposed fixes but not apply them.
Set the `DRY_RUN` environment variable to `true` before running:

```powershell
$env:DRY_RUN = 'true'
node fix_wheel_cycle_state.js
```

What it does
- For each user, reads `users/{uid}/wheel/cycle`.
- Validates `state` as an integer in the expected range.
- If invalid, sets `state` to `0` (idle) and preserves `cycleCount`/`lastTransition` where possible.
- Optionally posts a telemetry event to `TELEMETRY_URL` if provided.

Notes
- This script performs in-place fixes. Review and back up data if you want an audit trail before running.
- You can adapt the script to write fixes to a separate audit collection instead of mutating the original records.
