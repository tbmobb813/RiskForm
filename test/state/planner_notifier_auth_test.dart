import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/state/planner_notifier.dart';
import 'package:riskform/models/trade_inputs.dart';
import 'package:riskform/models/payoff_result.dart';
import 'package:riskform/models/risk_result.dart';
import 'package:riskform/models/trade_plan.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/services/engines/payoff_engine.dart';
import 'package:riskform/services/engines/risk_engine.dart';
import 'package:riskform/services/data/trade_plan_repository.dart';

// Minimal fakes mirroring test/state/planner_notifier_test.dart
class FakeTradePlanRepository implements TradePlanRepository {
  @override
  Future<void> savePlan(TradePlan plan) async {}

  @override
  Future<void> savePlanAndUpdateWheel(TradePlan plan, {bool persistPlan = true}) async {}

  @override
  Future<List<TradePlan>> fetchPlans() async => [];
}

class FakePayoffEngine extends PayoffEngine {
  @override
  Future<PayoffResult> compute({required String strategyId, required TradeInputs inputs}) async {
    return PayoffResult(maxGain: 0, maxLoss: 0, breakeven: 0, capitalRequired: 0);
  }
}

class FakeRiskEngine extends RiskEngine {
  FakeRiskEngine(): super(const AccountContext(accountSize:1000,buyingPower:1000));
  @override
  Future<RiskResult> compute({required String strategyId, required TradeInputs inputs, required PayoffResult payoff}) async {
    return RiskResult(riskPercentOfAccount:0, assignmentExposure:false, capitalLocked:0, warnings: []);
  }
}

void main() {
  test('executeTrade fails fast when user not authenticated', () async {
    final repo = FakeTradePlanRepository();
    final payoff = FakePayoffEngine();
    final risk = FakeRiskEngine();

    final notifier = PlannerNotifier(repo, payoff, risk);

    notifier.setStrategy('csp', 'Cash Secured Put', 'desc');
    notifier.updateInputs(TradeInputs(strike: 50.0, premiumReceived: 2.0));

    final result = await notifier.executeTrade();
    expect(result, isFalse);
    expect(notifier.state.errorMessage, 'Authentication required to execute trades.');
  });
}
