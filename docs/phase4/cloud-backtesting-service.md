# CloudBacktestService (Client-Side)

The CloudBacktestService is the client-facing interface for submitting backtest jobs to the cloud, monitoring their status, and retrieving results.

It integrates with:
- Firestore (job + result storage)
- CloudBacktestJob model
- CloudBacktestResult model
- BacktestConfig
- BacktestResult

---

## Responsibilities

1. Submit a new cloud backtest job.
2. Stream job status updates.
3. Fetch completed results.
4. List past cloud backtests for the user.
5. Integrate with Backtest UI ("Run in Cloud" button).

---

## Firestore Collections

### `backtestJobs/{jobId}`
Stores job metadata and status.

### `backtestResults/{jobId}`
Stores completed results.

---

## CloudBacktestService API

### Methods

#### `Future<String> submitJob(BacktestConfig config)`
Creates a new job document with status `"queued"`.

#### `Stream<CloudBacktestJob?> jobStream(String jobId)`
Real-time updates for job status.

#### `Stream<CloudBacktestJob?> watchJob(String jobId)`
Alias for jobStream - real-time updates for job status.

#### `Future<CloudBacktestResult?> getResult(String jobId)`
Fetches the completed result if available.

#### `Stream<CloudBacktestResult?> resultStream(String jobId)`
Real-time updates for job result.

#### `Stream<List<CloudBacktestJob>> watchUserJobs(String userId)`
Streams all jobs for the current user.

#### `Future<List<CloudBacktestJob>> listJobs({String? userId, int limit})`
Fetches jobs with optional filtering.

---

## Dart Implementation

Location: `lib/services/firebase/cloud_backtest_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../models/cloud/cloud_backtest_job.dart';
import '../../models/cloud/cloud_backtest_result.dart';

class CloudBacktestService {
  final FirebaseFirestore _fs;
  final Uuid _uuid = const Uuid();

  CloudBacktestService({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _jobs => _fs.collection('backtestJobs');
  CollectionReference get _results => _fs.collection('backtestResults');

  Future<String> submitJob({
    required String userId,
    required Map<String, dynamic> configMap,
    String engineVersion = '1.0.0',
    int? priority,
  }) async {
    final jobId = _uuid.v4();
    final now = DateTime.now();
    final doc = {
      'jobId': jobId,
      'userId': userId,
      'submittedAt': now.toIso8601String(),
      'startedAt': null,
      'completedAt': null,
      'status': CloudBacktestStatus.queued.toString(),
      'configUsed': configMap,
      'engineVersion': engineVersion,
      'priority': priority,
      'errorMessage': null,
    };
    await _jobs.doc(jobId).set(doc);
    return jobId;
  }

  Future<CloudBacktestJob?> getJob(String jobId) async {
    final snap = await _jobs.doc(jobId).get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return null;
    return CloudBacktestJob.fromMap(data);
  }

  Stream<CloudBacktestJob?> jobStream(String jobId) {
    return _jobs.doc(jobId).snapshots().map((snap) {
      final d = snap.data() as Map<String, dynamic>?;
      return d == null ? null : CloudBacktestJob.fromMap(d);
    });
  }

  /// Alias for jobStream
  Stream<CloudBacktestJob?> watchJob(String jobId) => jobStream(jobId);

  Future<void> writeResult(CloudBacktestResult result) async {
    await _results.doc(result.jobId).set(result.toMap());
  }

  Future<CloudBacktestResult?> getResult(String jobId) async {
    final snap = await _results.doc(jobId).get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return null;
    return CloudBacktestResult.fromMap(data);
  }

  Stream<CloudBacktestResult?> resultStream(String jobId) {
    return _results.doc(jobId).snapshots().map((snap) {
      final d = snap.data() as Map<String, dynamic>?;
      return d == null ? null : CloudBacktestResult.fromMap(d);
    });
  }

  Stream<List<CloudBacktestJob>> watchUserJobs(String userId) {
    return _jobs
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CloudBacktestJob.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<List<CloudBacktestJob>> listJobs({String? userId, int limit = 50}) async {
    Query q = _jobs;
    if (userId != null) q = q.where('userId', isEqualTo: userId);
    q = q.orderBy('submittedAt', descending: true).limit(limit);
    final snaps = await q.get();
    return snaps.docs
        .map((d) => CloudBacktestJob.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }
}
```

---

## Provider Setup

Location: `lib/state/backtest_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase/cloud_backtest_service.dart';

final cloudBacktestServiceProvider = Provider<CloudBacktestService>((ref) {
  return CloudBacktestService(firestore: FirebaseFirestore.instance);
});
```

---

## Usage in Backtest UI

### Submit a cloud job

```dart
final cloud = ref.read(cloudBacktestServiceProvider);
final auth = ref.read(authServiceProvider);

final jobId = await cloud.submitJob(
  userId: auth.currentUserId!,
  configMap: currentConfig.toMap(),
);
```

### Watch job status

```dart
StreamBuilder<CloudBacktestJob?>(
  stream: cloud.watchJob(jobId),
  builder: (_, snapshot) {
    if (!snapshot.hasData) return Text("Waiting...");
    final job = snapshot.data!;
    return Text("Status: ${job.status.name}");
  },
);
```

### Fetch result when completed

```dart
final result = await cloud.getResult(jobId);
if (result != null) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BacktestScreen(config: result.backtestResult.configUsed),
    ),
  );
}
```

---

## UI Integration

The BacktestScreen includes a **"Run in Cloud"** button that:

1. Checks user authentication
2. Submits the job via CloudBacktestService
3. Displays real-time job status card
4. Shows notifications on completion/failure

---

## CloudJobStatusScreen

A dedicated screen for monitoring cloud job status. Displays:

- Job status with color-coded indicator
- Timestamps (submitted, started, completed)
- Error message if failed
- Result preview when ready
- Navigation to full results

---

## Summary

CloudBacktestService provides:

- Job submission
- Job status streaming (jobStream / watchJob)
- Result retrieval (getResult / resultStream)
- User job listing (watchUserJobs / listJobs)
- Clean integration with Firestore
- Seamless UI hooks

This completes the **client-side foundation** for cloud backtesting.
