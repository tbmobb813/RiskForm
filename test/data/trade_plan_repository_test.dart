import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riskform/services/data/trade_plan_repository.dart';
import 'package:riskform/services/firebase/trade_plan_service.dart';
import 'package:riskform/services/firebase/auth_service.dart';
import 'package:riskform/services/firebase/wheel_cycle_service.dart';
import 'package:riskform/models/trade_plan.dart';
import 'package:riskform/models/trade_inputs.dart';
import 'package:riskform/models/payoff_result.dart';
import 'package:riskform/models/risk_result.dart';

class FakeService extends Mock implements TradePlanService {}
class FakeAuth extends Mock implements AuthService {}
class FakeWheel extends Mock implements WheelCycleService {}

void main() {
  test('savePlan throws when no user', () async {
    final service = FakeService();
    final auth = FakeAuth();
    when(() => auth.currentUserId).thenReturn(null);

    final repo = TradePlanRepository(service, auth, FakeWheel());
    final plan = TradePlan(
      id: 'p1',
      strategyId: 'csp',
      strategyName: 'S',
      inputs: const TradeInputs(),
      payoff: PayoffResult(maxGain: 10, maxLoss: -5, breakeven: 1, capitalRequired: 100),
      risk: RiskResult(riskPercentOfAccount: 1.0, assignmentExposure: false, capitalLocked: 0.0, warnings: []),
      notes: '',
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(repo.savePlan(plan), throwsA(isA<Exception>()));
  });

  test('fetchPlans throws when no user', () async {
    final service = FakeService();
    final auth = FakeAuth();
    when(() => auth.currentUserId).thenReturn(null);

    final repo = TradePlanRepository(service, auth, FakeWheel());

    expect(repo.fetchPlans(), throwsA(isA<Exception>()));
  });
}
