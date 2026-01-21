import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:riskform/strategy_cockpit/screens/strategy_performance_section.dart';
import 'package:riskform/strategy_cockpit/viewmodels/strategy_performance_viewmodel.dart';
import 'package:riskform/strategy_cockpit/services/strategy_health_service.dart';
import 'package:riskform/models/strategy_health_snapshot.dart';

class FakeHealthService implements StrategyHealthService {
  final StreamController<StrategyHealthSnapshot?> _ctrl = StreamController.broadcast();

  @override
  Stream<StrategyHealthSnapshot?> watchHealth(String strategyId) => _ctrl.stream;

  void add(StrategyHealthSnapshot? s) => _ctrl.add(s);

  Future<void> close() async => await _ctrl.close();

  // The following methods are unused in tests and implemented as no-ops.
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

void main() {
  testWidgets('Performance section shows win rate from health snapshot', (WidgetTester tester) async {
    final fake = FakeHealthService();
    final vm = StrategyPerformanceViewModel(strategyId: 's1', healthService: fake);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StrategyPerformanceSection(strategyId: 's1', viewModel: vm)),
    ));

    // Initially shows loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Send a snapshot: one win, one loss -> win rate 0.5 -> 50.0%
    final snapshot = StrategyHealthSnapshot(
      strategyId: 's1',
      pnlTrend: [10.0, -5.0],
      disciplineTrend: [],
      regimePerformance: {},
      cycleSummaries: [
        {'pnl': 10.0, 'id': 'c1'},
        {'pnl': -5.0, 'id': 'c2'},
      ],
      regimeWeaknesses: [],
      currentRegime: null,
      currentRegimeHint: null,
      updatedAt: DateTime.now(),
    );

    fake.add(snapshot);
    await tester.pumpAndSettle();

    expect(find.text('50.0%'), findsOneWidget);

    await fake.close();
  });
}
