import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:riskform/strategy_cockpit/screens/strategy_actions_section.dart';
import 'package:riskform/strategy_cockpit/viewmodels/strategy_cockpit_viewmodel.dart';
import 'package:riskform/services/strategy/strategy_service.dart';
import 'package:riskform/models/strategy.dart';
import 'package:riskform/strategy_cockpit/services/strategy_health_service.dart';
import 'package:riskform/models/strategy_health_snapshot.dart';
import 'package:riskform/strategy_cockpit/services/strategy_backtest_service.dart';
import 'package:riskform/regime/regime_service.dart';

class FakeStrategyService implements StrategyService {
  Map<String, dynamic>? _strategy;

  @override
  Future<String> createStrategy({required String name, String? description, List<String> tags = const [], Map<String, dynamic>? constraints, bool experimental = false}) async => 's1';

  @override
  Future<void> updateStrategy({required String strategyId, String? name, String? description, List<String>? tags, Map<String, dynamic>? constraints}) async {}

  @override
  Future<void> changeStrategyState({required String strategyId, required StrategyState nextState, String? reason}) async {}

  @override
  Stream<List<Map<String, dynamic>>> watchStrategies() async* {
    yield [];
  }

  @override
  Stream<Map<String, dynamic>?> watchStrategy(String strategyId) async* {
    yield {
      'id': strategyId,
      'name': 'Test',
      'state': 'active',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }
}

class FakeHealthService implements StrategyHealthService {
  @override
  Stream<StrategyHealthSnapshot?> watchHealth(String strategyId) => Stream.value(null);

  @override
  Future<StrategyHealthSnapshot?> fetchLatestHealth(String strategyId) async => null;

  @override
  Future<void> saveHealthSnapshot(StrategyHealthSnapshot snapshot) async {}

  @override
  Future<void> updateHealthFields({required String strategyId, Map<String, dynamic>? fields}) async {}

  @override
  Future<void> markHealthDirtyInTx({required dynamic tx, required String strategyId}) async {}

  @override
  Future<void> recomputeHealth(String strategyId) async {}
}

class FakeBacktestService implements StrategyBacktestService {
  @override
  Stream<Map<String, dynamic>?> watchLatestBacktest(String strategyId) => Stream.value(null);

  @override
  Stream<List<Map<String, dynamic>>> watchBacktestHistory(String strategyId) => Stream.value([]);

  @override
  Stream<List<Map<String, dynamic>>> watchBacktestJobs(String strategyId) => Stream.value([]);

  @override
  Future<String> createBacktestJob({required String strategyId, required Map<String, dynamic> parameters}) async => 'job-1';

  @override
  Future<void> updateJobStatus({required String jobId, required String status, Map<String, dynamic>? result}) async {}

  @override
  Future<void> saveBacktestResult({required String jobId, required String strategyId, required Map<String, dynamic> summary, required List<double> pnlCurve, required Map<String, dynamic> regimeBreakdown}) async {}

  @override
  Future<void> runBacktest(String strategyId, Map<String, dynamic> params) async {}
}

class FakeRegimeService implements RegimeService {
  @override
  Stream<String?> watchCurrentRegime() => Stream.value(null);
}

void main() {
  testWidgets('Actions section shows lifecycle buttons and planner', (WidgetTester tester) async {
    final fake = FakeStrategyService();
    final fakeHealth = FakeHealthService();
    final fakeBacktest = FakeBacktestService();
    final fakeRegime = FakeRegimeService();
    final vm = StrategyCockpitViewModel(
      strategyId: 's1',
      strategyService: fake,
      healthService: fakeHealth,
      backtestService: fakeBacktest,
      regimeService: fakeRegime,
    );

    await tester.pumpWidget(MaterialApp(
      routes: {'/planner': (ctx) => const Scaffold(body: Text('Planner'))},
      home: Scaffold(body: StrategyActionsSection(strategyId: 's1', viewModel: vm)),
    ));

    // Initially loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Planner button present
    expect(find.text('Open Planner'), findsOneWidget);

    // Tap planner
    await tester.tap(find.text('Open Planner'));
    await tester.pumpAndSettle();

    expect(find.text('Planner'), findsOneWidget);
  });
}
