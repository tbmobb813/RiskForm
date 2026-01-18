import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_2/screens/planner/save_plan/save_plan_screen.dart';
import 'package:flutter_application_2/state/planner_notifier.dart';
import 'package:flutter_application_2/state/planner_state.dart';
import 'package:flutter_application_2/models/payoff_result.dart';
import 'package:flutter_application_2/models/account_context.dart';
import 'package:flutter_application_2/models/comparison/comparison_config.dart';
import 'package:flutter_application_2/services/engines/comparison_runner.dart';
import 'package:flutter_application_2/services/engines/backtest_engine.dart';
import 'package:flutter_application_2/state/comparison_provider.dart';
import 'package:flutter_application_2/state/account_context_provider.dart';

class _FakePlannerNotifier extends StateNotifier<PlannerState> implements PlannerNotifier {
  _FakePlannerNotifier()
      : super(PlannerState.initial().copyWith(
          strategyId: 'wheel',
          strategyName: 'Wheel',
          payoff: PayoffResult(maxGain: 1000, maxLoss: -500, breakeven: 100.0, capitalRequired: 1000),
        ));

  // Implement required methods used by UI
  @override
  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  @override
  Future<bool> savePlan() async => true;
}

void main() {
  testWidgets('Compare Parameter Sweep navigates to ComparisonScreen', (tester) async {
    final fakePlannerProvider = StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
      return _FakePlannerNotifier();
    });

    final fakeComparisonProvider = Provider<ComparisonRunner>((ref) => ComparisonRunner(engine: BacktestEngine()));

    final fakeAccountProvider = Provider.autoDispose((ref) => const AccountContext(accountSize: 10000.0, buyingPower: 10000.0));

    await tester.pumpWidget(
      ProviderScope(overrides: [
        plannerNotifierProvider.overrideWithProvider(fakePlannerProvider),
        comparisonRunnerProvider.overrideWithValue(ComparisonRunner(engine: BacktestEngine())),
        accountContextProvider.overrideWithValue(
          AsyncValue.data(const AccountContext(accountSize: 10000.0, buyingPower: 10000.0)),
        ),
      ],
      child: const MaterialApp(home: SavePlanScreen())),
    );

    await tester.pumpAndSettle();

    // Find the compare button and tap it
    final finder = find.text('Compare Parameter Sweep');
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();

    // Expect ComparisonScreen app bar title
    expect(find.text('Strategy Comparison'), findsOneWidget);
  });
}
