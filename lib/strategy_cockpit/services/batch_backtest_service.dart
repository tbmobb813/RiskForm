import 'package:cloud_firestore/cloud_firestore.dart';

import 'backtest_comparison_service.dart';

class BatchBacktestService {
  final FirebaseFirestore _firestore;
  final BacktestComparisonService _comparisonService;

  BatchBacktestService({
    FirebaseFirestore? firestore,
    BacktestComparisonService? comparisonService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _comparisonService = comparisonService ?? BacktestComparisonService();

  CollectionReference<Map<String, dynamic>> _batches(String strategyId) =>
      _firestore
          .collection('strategyBacktests')
          .doc(strategyId)
          .collection('batches');

  CollectionReference<Map<String, dynamic>> _runs(String strategyId) =>
      _firestore
          .collection('strategyBacktests')
          .doc(strategyId)
          .collection('runs');

  // ------------------------------------------------------------
  // Create a batch job from a parameter grid
  // ------------------------------------------------------------
  Future<String> createBatchJob({
    required String strategyId,
    required List<Map<String, dynamic>> parameterGrid,
  }) async {
    final batchRef = _batches(strategyId).doc();
    final now = DateTime.now();

    // 1. Create batch doc
    await batchRef.set({
      'createdAt': now,
      'parameterGrid': parameterGrid,
      'runIds': [],
      'status': 'queued',
      'summary': null,
    });

    // 2. Create run jobs for each parameter set
    final runIds = <String>[];

    for (final params in parameterGrid) {
      final runRef = _runs(strategyId).doc();
      runIds.add(runRef.id);

      await runRef.set({
        'createdAt': now,
        'parameters': params,
        'status': 'queued',
        'metrics': null,
        'regimeBreakdown': null,
        'batchId': batchRef.id,
      });
    }

    // 3. Update batch with runIds
    await batchRef.update({'runIds': runIds});

    return batchRef.id;
  }

  // ------------------------------------------------------------
  // Called by Cloud Worker when all runs complete
  // ------------------------------------------------------------
  Future<void> finalizeBatch({
    required String strategyId,
    required String batchId,
  }) async {
    final batchRef = _batches(strategyId).doc(batchId);
    final batchSnap = await batchRef.get();

    if (!batchSnap.exists) return;

    final data = batchSnap.data() ?? <String, dynamic>{};
    final runIds = List<String>.from(data['runIds'] ?? []);

    // Load all completed runs
    final runDocs = await Future.wait(
      runIds.map((id) => _runs(strategyId).doc(id).get()),
    );

    final completedRuns = runDocs
        .where((d) => (d.data()?['status'] == 'complete'))
        .map((d) => {
              'runId': d.id,
              ...?d.data(),
            })
        .toList();

    if (completedRuns.isEmpty) {
      await batchRef.update({
        'status': 'failed',
        'summary': {
          'summaryNote': 'No completed runs.',
        },
      });
      return;
    }

    // Use comparison engine to compute summary
    final best = _comparisonService.findBest(completedRuns);
    final worst = _comparisonService.findWorst(completedRuns);
    final regimeWeaknesses =
        _comparisonService.computeRegimeWeaknesses(completedRuns);

    final comparison = _comparisonService.buildSummaryNote(
      best,
      worst,
      regimeWeaknesses,
    );

    // Write summary
    await batchRef.update({
      'status': 'complete',
      'summary': {
        'bestConfig': best?['parameters'],
        'worstConfig': worst?['parameters'],
        'regimeWeaknesses': regimeWeaknesses,
        'summaryNote': comparison,
      },
    });
  }
}
