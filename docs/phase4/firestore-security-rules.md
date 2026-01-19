# Firestore Security Rules — Cloud Backtesting

These rules secure the two cloud backtesting collections:

- `backtestJobs`
- `backtestResults`

They enforce:
- Users can submit jobs
- Users can read only their own jobs/results
- Users cannot modify job status
- Users cannot write results
- Cloud Worker (server) can update jobs and write results

---

## 1. Assumptions

- Authentication is required (`request.auth != null`)
- Cloud Worker uses Firebase Admin SDK (bypasses rules)
- Client uses Firestore client SDK (rules enforced)

---

## 2. Rules Overview

### backtestJobs
- **Create:** allowed by authenticated users
- **Read:** allowed only if `job.userId == request.auth.uid`
- **Update:** denied for clients (only Cloud Worker can update)
- **Delete:** denied

### backtestResults
- **Create:** denied for clients (only Cloud Worker can write)
- **Read:** allowed only if `result.userId == request.auth.uid`
- **Update/Delete:** denied

---

## 3. Full Firestore Rules

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ---------------------------
    // backtestJobs
    // ---------------------------
    match /backtestJobs/{jobId} {

      // CREATE: user can submit a job
      allow create: if request.auth != null
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.status == "CloudBacktestStatus.queued";

      // READ: user can read only their own jobs
      allow get, list: if request.auth != null
                       && resource.data.userId == request.auth.uid;

      // UPDATE: user cannot update job status or modify job
      // Only Cloud Worker (Admin SDK) can update
      allow update: if false;

      // DELETE: never allowed
      allow delete: if false;
    }

    // ---------------------------
    // backtestResults
    // ---------------------------
    match /backtestResults/{jobId} {

      // CREATE: only Cloud Worker (Admin SDK) can write
      allow create: if false;

      // READ: user can read only their own results
      allow get: if request.auth != null
                 && resource.data.userId == request.auth.uid;

      // LIST: user can list only their own results
      allow list: if request.auth != null
                  && resource.data.userId == request.auth.uid;

      // UPDATE/DELETE: never allowed
      allow update, delete: if false;
    }
  }
}
```

---

## 4. Explanation

### Why users can create jobs
Submitting a job is a client action, so users must be allowed to write:

```firestore
allow create: if request.resource.data.userId == request.auth.uid
```

This prevents impersonation.

---

### Why users cannot update jobs
If users could update jobs, they could:

- mark their job as `"completed"`
- inject fake results
- overwrite timestamps
- break the worker trigger

So:

```firestore
allow update: if false;
```

Only the Cloud Worker (Admin SDK) can update.

---

### Why users cannot write results
Results must be trusted, deterministic, and server-generated.

So:

```firestore
allow create: if false;
```

Only the Cloud Worker can write results.

---

### Why users can read only their own jobs/results
Prevents cross-user access:

```firestore
resource.data.userId == request.auth.uid
```

---

## 5. Optional Hardening (Recommended)

### Prevent oversized configs
```firestore
&& request.resource.data.configUsed.size() < 20000
```

### Validate required fields on create
```firestore
&& request.resource.data.keys().hasAll(['jobId', 'userId', 'configUsed', 'status', 'engineVersion'])
```

### Prevent client from setting server timestamps
```firestore
&& !request.resource.data.keys().hasAny(['startedAt', 'completedAt'])
```

### Full hardened create rule
```firestore
allow create: if request.auth != null
              && request.resource.data.userId == request.auth.uid
              && request.resource.data.status == "CloudBacktestStatus.queued"
              && request.resource.data.keys().hasAll(['jobId', 'userId', 'configUsed', 'status', 'engineVersion'])
              && !request.resource.data.keys().hasAny(['startedAt', 'completedAt'])
              && request.resource.data.configUsed.size() < 20000;
```

---

## 6. Index Requirements

For the `watchUserJobs` query to work, create a composite index:

**Collection:** `backtestJobs`
**Fields:**
- `userId` (Ascending)
- `submittedAt` (Descending)

Create via Firebase Console or `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "backtestJobs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "submittedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 7. Summary

These rules ensure:

- Users can submit jobs
- Users can read their own jobs/results
- Users cannot tamper with job status
- Users cannot write results
- Cloud Worker has full write access via Admin SDK
- All data is isolated per user
- Backtesting pipeline is secure and deterministic

This is the correct security foundation for Phase 4 cloud execution.
