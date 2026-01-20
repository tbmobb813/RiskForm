import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/screens/planner/payoff/inputs_recap.dart';
import 'package:riskform/models/trade_inputs.dart';

void main() {
  testWidgets('InputsRecap shows title and entries when expanded', (WidgetTester tester) async {
    final inputs = TradeInputs(
      strike: 50.0,
      premiumPaid: 1.5,
      costBasis: 48.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: InputsRecap(inputs: inputs)),
      ),
    );

    // Title always visible
    expect(find.text('Trade Inputs'), findsOneWidget);

    // Expand to reveal entries
    await tester.tap(find.text('Trade Inputs'));
    await tester.pumpAndSettle();

    // Check for at least one entry label and value
    expect(find.text('Strike'), findsOneWidget);
    expect(find.text('50.0'), findsOneWidget);
  });
}
