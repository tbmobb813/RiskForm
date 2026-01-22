import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riskform/strategy_cockpit/strategy_cockpit_bundle.dart';
import 'package:riskform/strategy_cockpit/viewmodels/strategy_cockpit_viewmodel.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_recommendations_engine.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_narrative_engine.dart';
import 'package:riskform/models/strategy.dart';
import 'package:riskform/models/strategy_health_snapshot.dart';

class FakeVm extends ChangeNotifier implements StrategyCockpitViewModel {
  @override
  final String strategyId;
  @override
  bool isLoading = false;
  @override
  bool hasError = false;
  @override
  Strategy? strategy;
  @override
  StrategyHealthSnapshot? health;
  @override
  Map<String, dynamic>? latestBacktest;
  @override
  String? currentRegime;
  @override
  StrategyRecommendationsBundle? recommendations;
  @override
  StrategyNarrative? narrative;

  FakeVm({required this.strategyId, required this.strategy, this.recommendations}) {
    health = null;
    latestBacktest = null;
    currentRegime = null;
    narrative = null;
  }

  @override
  Future<void> pauseStrategy({String? reason}) async {}
  @override
  Future<void> resumeStrategy({String? reason}) async {}
  @override
  Future<void> retireStrategy({String? reason}) async {}
  @override
  void dispose() {}
}

void main() {
  testWidgets('Header shows RecommendationsPanel when VM has recommendations', (tester) async {
    final strat = Strategy(
      id: 's1',
      name: 'Test Strategy',
      description: 'desc',
      state: StrategyState.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final bundle = StrategyRecommendationsBundle(
      generatedAt: DateTime.now(),
      recommendations: [
        StrategyRecommendation(category: 'risk', message: 'Reduce size by 20%', priority: 1),
      ],
    );

    final vm = FakeVm(strategyId: 's1', strategy: strat, recommendations: bundle);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StrategyHeader(strategyId: 's1', viewModel: vm))));

    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('Reduce size by 20%'), findsOneWidget);
  });
}
