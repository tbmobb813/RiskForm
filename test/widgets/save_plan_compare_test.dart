import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_2/screens/planner/save_plan/save_plan_screen.dart';
// planner notifier/state/payoff imports not required directly in this test
import 'package:flutter_application_2/models/account_context.dart';
import 'package:flutter_application_2/models/trade_plan.dart';
import 'package:flutter_application_2/services/engines/comparison_runner.dart';
import 'package:flutter_application_2/services/engines/backtest_engine.dart';
import 'package:flutter_application_2/services/engines/option_pricing_engine.dart';
import 'package:flutter_application_2/state/comparison_provider.dart';
import 'package:flutter_application_2/state/account_context_provider.dart';
import 'package:flutter_application_2/services/data/trade_plan_repository.dart';
import 'package:flutter_application_2/services/engines/payoff_engine.dart';
import 'package:flutter_application_2/services/engines/risk_engine.dart';

// Minimal fake implementations to construct a PlannerNotifier for tests.
class _FakeTradePlanRepository implements TradePlanRepository {
  @override
  Future<void> savePlan(TradePlan plan) async {}

  @override
  Future<void> savePlanAndUpdateWheel(TradePlan plan, {bool persistPlan = true}) async {}

  @override
  Future<List<TradePlan>> fetchPlans() async => [];
}

void main() {
  test('ComparisonRunner returns empty results for empty config', () async {
    final runner = ComparisonRunner(engine: BacktestEngine(optionPricing: OptionPricingEngine()));
    final config = ComparisonConfig(configs: []);
    final result = await runner.run(config);
    expect(result.results, isEmpty);
  });
}
