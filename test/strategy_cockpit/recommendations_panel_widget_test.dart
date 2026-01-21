import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/strategy_cockpit/widgets/recommendations_panel.dart';
import 'package:riskform/strategy_cockpit/analytics/strategy_recommendations_engine.dart';

void main() {
  testWidgets('RecommendationsPanel shows top 3 and priority icons', (tester) async {
    final bundle = StrategyRecommendationsBundle(
      generatedAt: DateTime.now(),
      recommendations: [
        StrategyRecommendation(category: 'risk', message: 'Reduce size by 30%', priority: 1),
        StrategyRecommendation(category: 'parameter', message: 'Tighten delta to 0.15–0.2', priority: 3),
        StrategyRecommendation(category: 'regime', message: 'Sideways - favor income', priority: 4),
        StrategyRecommendation(category: 'consistency', message: 'Narrow width', priority: 2),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RecommendationsPanel(bundle: bundle))));

    // Top heading
    expect(find.text('Recommendations'), findsOneWidget);

    // Should show only top 3 messages
    expect(find.text('Reduce size by 30%'), findsOneWidget);
    expect(find.text('Tighten delta to 0.15–0.2'), findsOneWidget);
    expect(find.text('Sideways - favor income'), findsOneWidget);
    expect(find.text('Narrow width'), findsNothing);

    // Priority icons: look for '1' and '3' and '4' inside CircleAvatar
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}
