import 'package:cloud_firestore/cloud_firestore.dart';

class StrategyBacktestService {
  final FirebaseFirestore _firestore;

  StrategyBacktestService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // Collection references
  // ------------------------------------------------------------
  CollectionReference get _results =>
      _firestore.collection('strategyBacktestResults');

  CollectionReference get _jobs =>
      _firestore.collection('strategyBacktestJobs');

  // ------------------------------------------------------------
  // Watch Latest Backtest Result
  // ------------------------------------------------------------
  Stream<Map<String, dynamic>?> watchLatestBacktest(String strategyId) {
    return _results
        .where('strategyId', isEqualTo: strategyId)
        .orderBy('completedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    });
  }

  // ------------------------------------------------------------
  // Watch Backtest History (most recent first)
  // ------------------------------------------------------------
  Stream<List<Map<String, dynamic>>> watchBacktestHistory(
      String strategyId) {
    return _results
        .where('strategyId', isEqualTo: strategyId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  // ------------------------------------------------------------
  // Watch Backtest Jobs (queued, running, completed)
  // ------------------------------------------------------------
  Stream<List<Map<String, dynamic>>> watchBacktestJobs(
      String strategyId) {
    return _jobs
        .where('strategyId', isEqualTo: strategyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  // ------------------------------------------------------------
  // Create a new backtest job (Phase 5.5)
  // ------------------------------------------------------------
  Future<String> createBacktestJob({
    required String strategyId,
    required Map<String, dynamic> parameters,
  }) async {
    final docRef = _jobs.doc();

    await docRef.set({
      'strategyId': strategyId,
      'parameters': parameters,
      'status': 'queued',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ------------------------------------------------------------
  // Update job status (Cloud Run worker will call this)
  // ------------------------------------------------------------
  Future<void> updateJobStatus({
    required String jobId,
    required String status, // queued | running | completed | failed
    Map<String, dynamic>? result,
  }) async {
    final update = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (result != null) {
      update['result'] = result;
    }

    await _jobs.doc(jobId).update(update);
  }

  // ------------------------------------------------------------
  // Save completed backtest result
  // ------------------------------------------------------------
  Future<void> saveBacktestResult({
    required String jobId,
    required String strategyId,
    required Map<String, dynamic> summary,
    required List<double> pnlCurve,
    required Map<String, dynamic> regimeBreakdown,
  }) async {
    await _results.doc(jobId).set({
      'strategyId': strategyId,
      'completedAt': FieldValue.serverTimestamp(),
      'summary': summary,
      'pnlCurve': pnlCurve,
      'regimeBreakdown': regimeBreakdown,
    });
  }
}
