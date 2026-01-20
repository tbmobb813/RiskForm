import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BatchBacktestViewModel extends ChangeNotifier {
  final String strategyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? batchId;
  Map<String, dynamic>? batchData;
  bool loading = false;

  BatchBacktestViewModel({required this.strategyId});

  Future<void> createBatch(List<Map<String, dynamic>> grid) async {
    loading = true;
    notifyListeners();

    final now = DateTime.now();
    final batchRef = _firestore
        .collection('strategyBacktests')
        .doc(strategyId)
        .collection('batches')
        .doc();

    await batchRef.set({
      'createdAt': now,
      'parameterGrid': grid,
      'runIds': [],
      'status': 'queued',
      'summary': null,
    });

    batchId = batchRef.id;
    loading = false;
    notifyListeners();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBatch() {
    if (batchId == null) {
      // empty stream
      return const Stream.empty();
    }

    return _firestore
        .collection('strategyBacktests')
        .doc(strategyId)
        .collection('batches')
        .doc(batchId)
        .snapshots();
  }
}
