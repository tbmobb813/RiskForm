import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:riskform/strategy_cockpit/screens/strategy_regime_section.dart';
import 'package:riskform/strategy_cockpit/viewmodels/strategy_regime_viewmodel.dart';
import 'package:riskform/strategy_cockpit/services/strategy_health_service.dart';
import 'package:riskform/models/strategy_health_snapshot.dart';

class FakeRegimeHealthService implements StrategyHealthService {
  final StreamController<StrategyHealthSnapshot?> _ctrl = StreamController.broadcast();

  @override
  Stream<StrategyHealthSnapshot?> watchHealth(String strategyId) => _ctrl.stream;

  void add(StrategyHealthSnapshot? s) => _ctrl.add(s);

  Future<void> close() async => await _ctrl.close();

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
  testWidgets('Regime section shows current regime and table', (WidgetTester tester) async {
    final fake = FakeRegimeHealthService();
    final vm = StrategyRegimeViewModel(strategyId: 's1', healthService: fake);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StrategyRegimeSection(strategyId: 's1', viewModel: vm)),
    ));

    final snapshot = StrategyHealthSnapshot(
      strategyId: 's1',
      pnlTrend: [],
      disciplineTrend: [],
      regimePerformance: {},
      cycleSummaries: [
        {'cycleId': 'c1', 'pnl': -5.0, 'disciplineScore': 60.0, 'regime': 'uptrend'},
      ],
      regimeWeaknesses: [],
      currentRegime: 'uptrend',
      currentRegimeHint: 'Good in strength',
      updatedAt: DateTime.now(),
    );

    fake.add(snapshot);
    await tester.pumpAndSettle();

    expect(find.text('Current Regime'), findsOneWidget);
    expect(find.text('Regime Performance'), findsOneWidget);
    // Weakness messages are descriptive; ensure Underperforms flag appears
    expect(find.text('Underperforms in uptrend regimes'), findsOneWidget);

    await fake.close();
  });
}
