import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trade_plan.dart';

final tradePlanServiceProvider = Provider<TradePlanService>((ref) {
  return TradePlanService();
});

class TradePlanService {
  final FirebaseFirestore _db;

  TradePlanService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Future<void> savePlan({
    required String uid,
    required TradePlan plan,
  }) async {
    final ref = _db
        .collection("users")
        .doc(uid)
        .collection("trade_plans")
        .doc(plan.id);

    final data = Map<String, dynamic>.from(plan.toJson());
    // use server timestamps for createdAt/updatedAt so Firestore sets them
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await ref.set(data, SetOptions(merge: true));
  }

  Future<List<TradePlan>> fetchPlans(String uid) async {
    final snap = await _db
        .collection("users")
        .doc(uid)
        .collection("trade_plans")
        .orderBy("createdAt", descending: true)
        .get();

    return snap.docs.map((d) => TradePlan.fromDoc(d)).toList();
  }
}