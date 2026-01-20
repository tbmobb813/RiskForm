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

// Fakes
class FakeTradePlanRepository implements TradePlanRepository {
  bool saved = false;
  TradePlan? lastPlan;

  @override
  Future<void> savePlan(TradePlan plan) async {
    saved = true;
    lastPlan = plan;
  }

  @override
  Future<void> savePlanAndUpdateWheel(TradePlan plan, {bool persistPlan = true}) async {
    // For tests, just behave like savePlan
    await savePlan(plan);
  }

  @override
  Future<List<TradePlan>> fetchPlans() async => [];
}

class FakePayoffEngine extends PayoffEngine {
  @override
  Future<PayoffResult> compute({required String strategyId, required TradeInputs inputs}) async {
    return PayoffResult(
      maxGain: 100.0,
      maxLoss: 50.0,
      breakeven: 48.0,
      capitalRequired: 500.0,
    );
  }
}

class FakeRiskEngine extends RiskEngine {
  FakeRiskEngine(): super(const AccountContext(accountSize:10000.0,buyingPower:10000.0));

  @override
  Future<RiskResult> compute({required String strategyId, required TradeInputs inputs, required PayoffResult payoff}) async {
    return RiskResult(
      riskPercentOfAccount: 5.0,
      assignmentExposure: false,
      capitalLocked: 500.0,
      warnings: [],
    );
  }
}

void main() {
  test('PlannerNotifier computePayoff/computeRisk/savePlan flow', () async {
    final repo = FakeTradePlanRepository();
    final payoffEngine = FakePayoffEngine();
    final riskEngine = FakeRiskEngine();

    final notifier = PlannerNotifier(repo, payoffEngine, riskEngine);

    notifier.setStrategy('csp', 'Cash Secured Put', 'desc');
    notifier.updateInputs(TradeInputs(strike: 50.0, premiumReceived: 2.0));

    final gotPayoff = await notifier.computePayoff();
    expect(gotPayoff, isTrue);
    expect(notifier.state.payoff, isNotNull);

    final gotRisk = await notifier.computeRisk();
    expect(gotRisk, isTrue);
    expect(notifier.state.risk, isNotNull);

    final saved = await notifier.savePlan();
    expect(saved, isTrue);
    expect(repo.saved, isTrue);
    expect(repo.lastPlan, isNotNull);
    // After save the notifier resets
    expect(notifier.state.strategyId, isNull);
  });
}
