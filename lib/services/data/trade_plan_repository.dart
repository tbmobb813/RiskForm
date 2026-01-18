import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trade_plan.dart';
import '../firebase/trade_plan_service.dart';
import '../firebase/auth_service.dart';

final tradePlanRepositoryProvider = Provider<TradePlanRepository>((ref) {
  final service = ref.read(tradePlanServiceProvider);
  final auth = ref.read(authServiceProvider);
  return TradePlanRepository(service, auth);
});

class TradePlanRepository {
  final TradePlanService _service;
  final AuthService _auth;

  TradePlanRepository(this._service, this._auth);

  Future<void> savePlan(TradePlan plan) async {
    final uid = _auth.currentUserId;
    if (uid == null) throw Exception("User not logged in.");

    await _service.savePlan(uid: uid, plan: plan);
  }

  Future<List<TradePlan>> fetchPlans() async {
    final uid = _auth.currentUserId;
    if (uid == null) throw Exception("User not logged in.");

    return _service.fetchPlans(uid);
  }
}