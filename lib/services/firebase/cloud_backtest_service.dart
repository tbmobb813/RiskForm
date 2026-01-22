import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/cloud/cloud_backtest_job.dart';
import '../../models/cloud/cloud_backtest_result.dart';

class CloudBacktestService {
  final FirebaseFirestore? _fs;
  final Uuid _uuid = const Uuid();
  final bool _noop;

  CloudBacktestService({FirebaseFirestore? firestore})
      : _fs = firestore ?? (() {
          try {
            return FirebaseFirestore.instance;
          } catch (_) {
            return null;
          }
        })(),
        _noop = false;

  /// No-op constructor used when Firestore isn't available (desktop dev).
  CloudBacktestService.noop()
      : _fs = null,
        _noop = true;

  CollectionReference get _jobs {
    if (_fs == null) throw StateError('Firestore not available');
    return _fs!.collection('backtestJobs');
  }

  CollectionReference get _results {
    if (_fs == null) throw StateError('Firestore not available');
    return _fs!.collection('backtestResults');
  }

  Future<String> submitJob({
    required String userId,
    required Map<String, dynamic> configMap,
    String engineVersion = '1.0.0',
    int? priority,
  }) async {
    final jobId = _uuid.v4();
    if (_noop || _fs == null) {
      return jobId;
    }
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
    if (_noop || _fs == null) return null;
    final snap = await _jobs.doc(jobId).get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return null;
    return CloudBacktestJob.fromMap(data);
  }

  Stream<CloudBacktestJob?> jobStream(String jobId) {
    if (_noop || _fs == null) return Stream.value(null);
    return _jobs.doc(jobId).snapshots().map((snap) {
      final d = snap.data() as Map<String, dynamic>?;
      return d == null ? null : CloudBacktestJob.fromMap(d);
    });
  }

  Future<void> writeResult(CloudBacktestResult result) async {
    if (_noop || _fs == null) return;
    await _results.doc(result.jobId).set(result.toMap());
  }

  Future<CloudBacktestResult?> getResult(String jobId) async {
    if (_noop || _fs == null) return null;
    final snap = await _results.doc(jobId).get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return null;
    return CloudBacktestResult.fromMap(data);
  }

  Stream<CloudBacktestResult?> resultStream(String jobId) {
    if (_noop || _fs == null) return Stream.value(null);
    return _results.doc(jobId).snapshots().map((snap) {
      final d = snap.data() as Map<String, dynamic>?;
      return d == null ? null : CloudBacktestResult.fromMap(d);
    });
  }

  /// Alias for jobStream - matches spec naming convention
  Stream<CloudBacktestJob?> watchJob(String jobId) => jobStream(jobId);

  /// Stream all jobs for a specific user, ordered by submission time
  Stream<List<CloudBacktestJob>> watchUserJobs(String userId) {
    if (_noop || _fs == null) return Stream.value(<CloudBacktestJob>[]);
    return _jobs
      .where('userId', isEqualTo: userId)
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
        .map((d) => CloudBacktestJob.fromMap(d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<CloudBacktestJob>> listJobs({String? userId, int limit = 50}) async {
    if (_noop || _fs == null) return <CloudBacktestJob>[];
    Query q = _jobs;
    if (userId != null) q = q.where('userId', isEqualTo: userId);
    q = q.orderBy('submittedAt', descending: true).limit(limit);
    final snaps = await q.get();
    return snaps.docs
        .map((d) => CloudBacktestJob.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }
}