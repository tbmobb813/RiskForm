import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/strategy_health_snapshot.dart';

class StrategyHealthService {
  final FirebaseFirestore _firestore;

  StrategyHealthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // Collection reference
  // ------------------------------------------------------------
  CollectionReference get _health =>
      _firestore.collection('strategyHealth');

  // ------------------------------------------------------------
  // Watch health snapshot for a strategy
  // ------------------------------------------------------------
  Stream<StrategyHealthSnapshot?> watchHealth(String strategyId) {
    return _health.doc(strategyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StrategyHealthSnapshot.fromFirestore(doc);
    });
  }

  // ------------------------------------------------------------
  // Fetch latest health snapshot once
  // ------------------------------------------------------------
  Future<StrategyHealthSnapshot?> fetchLatestHealth(
      String strategyId) async {
    final doc = await _health.doc(strategyId).get();
    if (!doc.exists) return null;
    return StrategyHealthSnapshot.fromFirestore(doc);
  }

  // ------------------------------------------------------------
  // Upsert health snapshot (for Cloud worker / batch jobs)
  // ------------------------------------------------------------
  Future<void> saveHealthSnapshot(
    StrategyHealthSnapshot snapshot,
  ) async {
    await _health.doc(snapshot.strategyId).set(
          snapshot.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // ------------------------------------------------------------
  // Partial update (e.g., only flags or regimePerformance)
  // ------------------------------------------------------------
  Future<void> updateHealthFields({
    required String strategyId,
    Map<String, dynamic>? fields,
  }) async {
    if (fields == null || fields.isEmpty) return;

    fields['updatedAt'] = FieldValue.serverTimestamp();

    await _health.doc(strategyId).update(fields);
  }
}
