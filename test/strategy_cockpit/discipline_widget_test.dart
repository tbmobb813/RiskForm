import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:riskform/strategy_cockpit/screens/strategy_discipline_section.dart';
import 'package:riskform/strategy_cockpit/viewmodels/strategy_discipline_viewmodel.dart';
import 'package:riskform/strategy_cockpit/services/strategy_health_service.dart';
import 'package:riskform/models/strategy_health_snapshot.dart';

class FakeDisciplineHealthService implements StrategyHealthService {
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
  testWidgets('Discipline section displays streaks and events', (WidgetTester tester) async {
    final fake = FakeDisciplineHealthService();
    final vm = StrategyDisciplineViewModel(strategyId: 's1', healthService: fake);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StrategyDisciplineSection(strategyId: 's1', viewModel: vm)),
    ));

    // Initially loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final snapshot = StrategyHealthSnapshot(
      strategyId: 's1',
      pnlTrend: [],
      disciplineTrend: [70, 65, 80],
      regimePerformance: {},
      cycleSummaries: [
        {'pnl': 5.0, 'id': 'c1', 'disciplineScore': 70.0},
      ],
      regimeWeaknesses: [],
      currentRegime: null,
      currentRegimeHint: null,
      updatedAt: DateTime.now(),
    );

    fake.add(snapshot);
    await tester.pumpAndSettle();

    // Check streak card labels present
    expect(find.text('Clean Cycles'), findsWidgets);
    expect(find.text('Adherence'), findsWidgets);

    await fake.close();
  });
}
