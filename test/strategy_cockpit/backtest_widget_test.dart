// ignore_for_file: override_on_non_overriding_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:riskform/strategy_cockpit/screens/strategy_backtest_section.dart';
import 'package:riskform/strategy_cockpit/viewmodels/strategy_backtest_viewmodel.dart';
import 'package:riskform/strategy_cockpit/services/strategy_backtest_service.dart';

class FakeBacktestService implements StrategyBacktestService {
  final Map<String, dynamic> _item = {
    'id': 'b1',
    'summary': {'totalPnl': 123.45, 'winRate': 0.55, 'cycles': 10},
    'completedAt': DateTime.now().toIso8601String()
  };

  @override
  Stream<Map<String, dynamic>?> watchLatestBacktest(String strategyId) => Stream.value(_item);

  @override
  Stream<List<Map<String, dynamic>>> watchBacktestHistory(String strategyId) => Stream.value([_item]);

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

void main() {
  testWidgets('Backtest section shows latest and history', (WidgetTester tester) async {
    final fake = FakeBacktestService();
    final vm = StrategyBacktestViewModel(strategyId: 's1', backtestService: fake);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StrategyBacktestSection(strategyId: 's1', viewModel: vm)),
    ));

    // Allow the viewmodel to fetch and build
    await tester.pumpAndSettle();

    expect(find.text('Latest Backtest'), findsOneWidget);
    expect(find.text('Backtest History'), findsOneWidget);
  });
}
