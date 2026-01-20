import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/screens/planner/components/payoff_summary_card.dart';
import 'package:riskform/models/payoff_result.dart';

void main() {
  testWidgets('PayoffSummaryCard displays values', (WidgetTester tester) async {
    final payoff = PayoffResult(maxGain: 200.0, maxLoss: 50.0, breakeven: 48.0, capitalRequired: 500.0);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayoffSummaryCard(payoff: payoff))));

    expect(find.text('Payoff Summary'), findsOneWidget);
    expect(find.text(r"$200.00"), findsOneWidget);
    expect(find.text(r"$50.00"), findsOneWidget);
    expect(find.text(r"$48.00"), findsOneWidget);
    expect(find.text(r"$500.00"), findsOneWidget);
  });
}
