import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/state/planner_notifier.dart';
import 'package:riskform/models/journal/journal_entry.dart';
import 'package:riskform/models/trade_inputs.dart';
import 'package:riskform/models/trade_plan.dart';
import 'package:riskform/services/data/trade_plan_repository.dart';
import 'package:riskform/services/engines/payoff_engine.dart';
import 'package:riskform/services/engines/risk_engine.dart';
import 'package:riskform/services/journal/journal_repository.dart';
import 'package:riskform/models/payoff_result.dart';
import 'package:riskform/models/risk_result.dart';
import 'package:riskform/models/account_context.dart';

// Minimal fakes reused from existing tests
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
    await savePlan(plan);
  }

  @override
  Future<List<TradePlan>> fetchPlans() async => [];
}

class FakePayoffEngine extends PayoffEngine {
  @override
  Future<PayoffResult> compute({required String strategyId, required TradeInputs inputs}) async {
    return PayoffResult(maxGain: 100.0, maxLoss: 50.0, breakeven: 48.0, capitalRequired: 500.0);
  }
}

class FakeRiskEngine extends RiskEngine {
  FakeRiskEngine(): super(const AccountContext(accountSize:10000.0,buyingPower:10000.0));

  @override
  Future<RiskResult> compute({required String strategyId, required TradeInputs inputs, required PayoffResult payoff}) async {
    return RiskResult(riskPercentOfAccount: 5.0, assignmentExposure: false, capitalLocked: 500.0, warnings: []);
  }
}

// Fake journal repository to capture add/update calls.
class FakeJournalRepo extends JournalRepository {
  final List<JournalEntry> added = [];
  final List<JournalEntry> updated = [];
  Completer<void>? updateCompleter;

  FakeJournalRepo() : super();

  @override
  Future<void> addEntry(JournalEntry entry) async {
    added.add(entry);
  }

  @override
  Future<void> updateEntry(JournalEntry entry) async {
    updated.add(entry);
    updateCompleter?.complete();
  }
}

void main() {
  test('setStrategy creates selection entry and async-enriches with small-account settings', () async {
    final repo = FakeTradePlanRepository();
    final payoffEngine = FakePayoffEngine();
    final riskEngine = FakeRiskEngine();
    final fakeJournal = FakeJournalRepo();

    // Provide uid and small-account settings via injection hooks.
    final notifier = PlannerNotifier(repo, payoffEngine, riskEngine, null, null, null, null, fakeJournal, () => 'test-uid', () async => {'maxOpenPositions': 3});

    fakeJournal.updateCompleter = Completer<void>();

    notifier.setStrategy('csp', 'Cash Secured Put', 'desc', symbol: 'XYZ');

    // addEntry should have been called synchronously
    expect(fakeJournal.added.length, 1);
    final added = fakeJournal.added.first;
    expect(added.type, 'selection');
    expect(added.data['strategyId'], 'csp');

    // wait for async enrichment to complete
    await fakeJournal.updateCompleter!.future;
    expect(fakeJournal.updated.length, 1);
    final enriched = fakeJournal.updated.first;
    expect(enriched.data['smallAccount'], true);
    expect(enriched.data['smallAccountSettings'], isA<Map<String, dynamic>>());
    expect((enriched.data['smallAccountSettings'] as Map)['maxOpenPositions'], 3);
  });

  test('savePlan creates plan_saved entry and enriches with small-account settings', () async {
    final repo = FakeTradePlanRepository();
    final payoffEngine = FakePayoffEngine();
    final riskEngine = FakeRiskEngine();
    final fakeJournal = FakeJournalRepo();

    final notifier = PlannerNotifier(repo, payoffEngine, riskEngine, null, null, null, null, fakeJournal, () => 'test-uid', () async => {'enabled': true});

    notifier.setStrategy('csp', 'Cash Secured Put', 'desc');
    notifier.updateInputs(TradeInputs(strike: 50.0, premiumReceived: 2.0));

    final gotPayoff = await notifier.computePayoff();
    expect(gotPayoff, isTrue);
    final gotRisk = await notifier.computeRisk();
    expect(gotRisk, isTrue);

    final saved = await notifier.savePlan();
    expect(saved, isTrue);

    // savePlan awaits enrichment, so updated should already be present
    expect(fakeJournal.added.length, greaterThanOrEqualTo(1));
    final planEntry = fakeJournal.added.firstWhere((e) => e.type == 'plan_saved', orElse: () => throw StateError('plan_saved not found'));
    expect(planEntry.data['strategyId'], 'csp');

    expect(fakeJournal.updated.length, greaterThanOrEqualTo(1));
    final enriched = fakeJournal.updated.firstWhere((e) => e.type == 'plan_saved', orElse: () => throw StateError('enriched plan_saved not found'));
    expect(enriched.data['smallAccount'], true);
    expect(enriched.data['smallAccountSettings'], isA<Map<String, dynamic>>());
  });
}
