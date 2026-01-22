import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'persisted_strategy.dart';

final strategyPersistenceServiceProvider = Provider<StrategyPersistenceService>((ref) => StrategyPersistenceService());

class StrategyPersistenceService {
  final FirebaseFirestore _db;

  StrategyPersistenceService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Future<void> saveStrategy({required String uid, required PersistedStrategy strategy}) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('state')
        .doc('active_strategy')
        .set(strategy.toJson());
  }

  Future<PersistedStrategy?> loadStrategy(String uid) async {
    final doc = await _db.collection('users').doc(uid).collection('state').doc('active_strategy').get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return PersistedStrategy.fromJson(Map<String, dynamic>.from(data));
  }
}
