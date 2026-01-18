import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_2/screens/planner/save_plan/save_plan_screen.dart';
// planner notifier/state/payoff imports not required directly in this test
import 'package:flutter_application_2/models/account_context.dart';
import 'package:flutter_application_2/models/trade_plan.dart';
import 'package:flutter_application_2/services/engines/comparison_runner.dart';
import 'package:flutter_application_2/services/engines/backtest_engine.dart';
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
  testWidgets('Compare Parameter Sweep navigates to ComparisonScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: [
        // ensure PlannerNotifier can be constructed without real services
        tradePlanRepositoryProvider.overrideWithValue(_FakeTradePlanRepository()),
        payoffEngineProvider.overrideWithValue(PayoffEngine()),
        riskEngineProvider.overrideWithValue(RiskEngine(const AccountContext(accountSize: 10000.0, buyingPower: 10000.0))),
        comparisonRunnerProvider.overrideWithValue(ComparisonRunner(engine: BacktestEngine())),
        accountContextProvider.overrideWithValue(const AsyncValue.data(AccountContext(accountSize: 10000.0, buyingPower: 10000.0))),
      ], child: const MaterialApp(home: SavePlanScreen())),
    );

    await tester.pumpAndSettle();

    final finder = find.text('Compare Parameter Sweep');
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();

    expect(find.text('Strategy Comparison'), findsOneWidget);
  });
}
