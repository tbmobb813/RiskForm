import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riskform/services/data/trade_plan_repository.dart';
import 'package:riskform/services/firebase/trade_plan_service.dart';
import 'package:riskform/services/firebase/auth_service.dart';
import 'package:riskform/services/firebase/wheel_cycle_service.dart';
import 'package:riskform/models/wheel_cycle.dart';
import 'package:riskform/models/position.dart';
import 'package:riskform/models/trade_plan.dart';
import 'package:riskform/models/trade_inputs.dart';
import 'package:riskform/models/payoff_result.dart';
import 'package:riskform/models/risk_result.dart';

class FakeService implements TradePlanService {
  String? savedUid;
  TradePlan? savedPlan;

  @override
  Future<void> savePlan({required String uid, required TradePlan plan}) async {
    savedUid = uid;
    savedPlan = plan;
  }

  @override
  Future<List<TradePlan>> fetchPlans(String uid) async {
    return [savedPlan!];
  }
}

class FakeWheelCycleService implements WheelCycleService {
  @override
  Future<WheelCycle?> getCycle(String uid) async => null;

  @override
  Future<WheelCycle> updateCycle({required String uid, WheelCycle? previous, required List<Position> positions, bool persist = true}) async {
    return previous ?? WheelCycle(state: WheelCycleState.idle);
  }

  @override
  Future<void> saveCycle(String uid, WheelCycle cycle) async {
    // no-op for tests
  }
}

class FakeAuth implements AuthService {
  final String? _uid;
  FakeAuth(this._uid);

  @override
  String? get currentUserId => _uid;

  @override
  User? get currentUser => null;

  @override
  bool get isAuthenticated => _uid != null;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<UserCredential> signInWithEmail({required String email, required String password}) async {
    return FakeUserCredential();
  }

  @override
  Future<UserCredential> signUpWithEmail({required String email, required String password}) async {
    return FakeUserCredential();
  }

  @override
  String requireAuth() {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');
    return uid;
  }
}

// Minimal fake UserCredential used by fake auth implementations in tests.
class FakeUserCredential implements UserCredential {
  @override
  final User? user = null;

  @override
  final AdditionalUserInfo? additionalUserInfo = null;

  @override
  final OAuthCredential? credential = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('TradePlanRepository.savePlan forwards to service with uid', () async {
    final service = FakeService();
    final auth = FakeAuth('user-123');
    final repo = TradePlanRepository(service, auth, FakeWheelCycleService());

    final plan = TradePlan(
      id: 'p1',
      strategyId: 'csp',
      strategyName: 'Cash Secured Put',
      inputs: TradeInputs(strike: 50.0),
      payoff: PayoffResult(maxGain: 100, maxLoss: 0, breakeven: 50, capitalRequired: 5000),
      risk: RiskResult(riskPercentOfAccount: 1.0, assignmentExposure: false, capitalLocked: 10.0, warnings: []),
      notes: '',
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.savePlan(plan);
    expect(service.savedUid, 'user-123');
    expect(service.savedPlan?.id, 'p1');
  });

  test('TradePlanRepository.fetchPlans returns service results', () async {
    final service = FakeService();
    final auth = FakeAuth('user-123');
    final repo = TradePlanRepository(service, auth, FakeWheelCycleService());

    final plan = TradePlan(
      id: 'p2',
      strategyId: 'csp',
      strategyName: 'Cash Secured Put',
      inputs: TradeInputs(strike: 51.0),
      payoff: PayoffResult(maxGain: 100, maxLoss: 0, breakeven: 50, capitalRequired: 5000),
      risk: RiskResult(riskPercentOfAccount: 1.0, assignmentExposure: false, capitalLocked: 10.0, warnings: []),
      notes: '',
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    service.savedPlan = plan;
    final list = await repo.fetchPlans();
    expect(list.length, 1);
    expect(list.first.id, 'p2');
  });
}
