import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/data/trade_plan_repository.dart';
import 'package:riskform/services/firebase/trade_plan_service.dart';
import 'package:riskform/services/firebase/auth_service.dart';
import 'package:riskform/services/firebase/wheel_cycle_service.dart';
import 'package:riskform/models/trade_plan.dart';
import 'package:riskform/models/wheel_cycle.dart';
import 'package:riskform/models/trade_inputs.dart';
import 'package:riskform/models/payoff_result.dart';
import 'package:riskform/models/risk_result.dart';

class FakeService implements TradePlanService {
  bool saved = false;
  @override
  Future<void> savePlan({required String uid, required TradePlan plan}) async {
    saved = true;
  }

  @override
  Future<List<TradePlan>> fetchPlans(String uid) async => [];
}

class FakeAuth implements AuthService {
  final String? uid;
  FakeAuth(this.uid);

  @override
  String? get currentUserId => uid;

  @override
  User? get currentUser => null;

  @override
  bool get isAuthenticated => uid != null;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  Future<UserCredential> signInWithEmail({required String email, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signUpWithEmail({required String email, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  String requireAuth() {
    if (uid == null) throw Exception('User not logged in.');
    return uid!;
  }
}

class FakeWheel extends WheelCycleService {
  bool updated = false;
  @override
  Future<WheelCycle> updateCycle({required String uid, WheelCycle? previous, required positions, bool persist = true}) async {
    updated = true;
    return WheelCycle(state: WheelCycleState.idle, lastTransition: null, cycleCount: 0);
  }
}

void main() {
  test('savePlanAndUpdateWheel persists and calls wheel update when positions inferred', () async {
    final service = FakeService();
    final auth = FakeAuth('u1');
    final wheel = FakeWheel();

    final repo = TradePlanRepository(service, auth, wheel);

    final plan = TradePlan(
      id: 'p1',
      strategyId: 'csp',
      strategyName: 'S',
      inputs: const TradeInputs(sharesOwned: 1),
      payoff: PayoffResult(maxGain: 1, maxLoss: -1, breakeven: 0, capitalRequired: 0),
      risk: RiskResult(riskPercentOfAccount:0.1, assignmentExposure:false, capitalLocked:0.0, warnings: []),
      notes: '',
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.savePlanAndUpdateWheel(plan, persistPlan: true);
    expect(service.saved, isTrue);
    expect(wheel.updated, isTrue);
  });
}
