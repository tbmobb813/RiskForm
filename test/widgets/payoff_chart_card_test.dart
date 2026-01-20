import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/screens/planner/components/payoff_chart_card.dart';
import 'package:riskform/models/payoff_result.dart';

void main() {
  testWidgets('PayoffChartCard shows placeholder text', (WidgetTester tester) async {
    final payoff = PayoffResult(maxGain: 0, maxLoss: 0, breakeven: 50.0, capitalRequired: 0);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayoffChartCard(payoff: payoff))));

    expect(find.text('Payoff Diagram'), findsOneWidget);
    expect(find.text('Payoff chart placeholder'), findsOneWidget);
  });
}
