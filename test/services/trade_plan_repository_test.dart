import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/data/trade_plan_repository.dart';
import 'package:flutter_application_2/services/firebase/trade_plan_service.dart';
import 'package:flutter_application_2/services/firebase/auth_service.dart';
import 'package:flutter_application_2/models/trade_plan.dart';
import 'package:flutter_application_2/models/trade_inputs.dart';
import 'package:flutter_application_2/models/payoff_result.dart';
import 'package:flutter_application_2/models/risk_result.dart';

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

class FakeAuth implements AuthService {
  final String? uid;
  FakeAuth(this.uid);

  @override
  String? get currentUserId => uid;
}

void main() {
  test('TradePlanRepository.savePlan forwards to service with uid', () async {
    final service = FakeService();
    final auth = FakeAuth('user-123');
    final repo = TradePlanRepository(service, auth);

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
    final repo = TradePlanRepository(service, auth);

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
