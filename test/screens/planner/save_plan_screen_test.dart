import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/models/payoff_result.dart';
import 'package:riskform/models/risk_result.dart';
import 'package:riskform/models/trade_inputs.dart';
import 'package:riskform/models/trade_plan.dart';
import 'package:riskform/screens/planner/save_plan/save_plan_screen.dart';
import 'package:riskform/screens/settings/sign_in_screen.dart';
import 'package:riskform/services/engines/payoff_engine.dart';
import 'package:riskform/services/engines/risk_engine.dart';
import 'package:riskform/services/data/trade_plan_repository.dart';
import 'package:riskform/services/firebase/auth_service.dart';
import 'package:riskform/state/planner_notifier.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class FakeTradePlanRepository implements TradePlanRepository {
  @override
  Future<void> savePlan(TradePlan plan) async {}

  @override
  Future<void> savePlanAndUpdateWheel(
    TradePlan plan, {
    bool persistPlan = true,
  }) async {}

  @override
  Future<List<TradePlan>> fetchPlans() async => [];
}

class FakePayoffEngine extends PayoffEngine {
  @override
  Future<PayoffResult> compute({
    required String strategyId,
    required TradeInputs inputs,
  }) async => PayoffResult(
    maxGain: 100.0,
    maxLoss: 50.0,
    breakeven: 48.0,
    capitalRequired: 500.0,
  );
}

class FakeRiskEngine extends RiskEngine {
  FakeRiskEngine()
    : super(const AccountContext(accountSize: 10000.0, buyingPower: 10000.0));

  @override
  Future<RiskResult> compute({
    required String strategyId,
    required TradeInputs inputs,
    required PayoffResult payoff,
  }) async => RiskResult(
    riskPercentOfAccount: 5.0,
    assignmentExposure: false,
    capitalLocked: 500.0,
    warnings: [],
  );
}

Future<PlannerNotifier> _signedOutNotifierWithValidState() async {
  final notifier = PlannerNotifier(
    FakeTradePlanRepository(),
    FakePayoffEngine(),
    FakeRiskEngine(),
    null, // regimeEngine
    null, // hintsService
    null, // executionService
    null, // liveSyncManager
    null, // journalRepo
    () => null, // getUid - signed out
  );
  notifier.setStrategy('csp', 'Cash-Secured Put', 'desc');
  notifier.updateInputs(TradeInputs(strike: 50.0, premiumReceived: 2.0));
  await notifier.computePayoff();
  await notifier.computeRisk();
  return notifier;
}

void main() {
  testWidgets(
    'Save Trade Plan while signed out shows a Sign In action that opens SignInScreen',
    (tester) async {
      final notifier = await _signedOutNotifierWithValidState();
      final mockAuth = MockFirebaseAuth();
      when(() => mockAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannerNotifierProvider.overrideWith((ref) => notifier),
            authServiceProvider.overrideWithValue(AuthService(mockAuth)),
          ],
          child: const MaterialApp(home: SavePlanScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Save Trade Plan'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Trade Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to save your trade plan.'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Execute Trade while signed out shows a Sign In action that opens SignInScreen',
    (tester) async {
      final notifier = await _signedOutNotifierWithValidState();
      final mockAuth = MockFirebaseAuth();
      when(() => mockAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannerNotifierProvider.overrideWith((ref) => notifier),
            authServiceProvider.overrideWithValue(AuthService(mockAuth)),
          ],
          child: const MaterialApp(home: SavePlanScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Execute Trade'),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Execute Trade'));
      await tester.pumpAndSettle();

      expect(
        find.text('Authentication required to execute trades.'),
        findsOneWidget,
      );
      expect(find.text('Sign In'), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    },
  );
}
