import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/screens/probability/probability_screen.dart';
import 'package:riskform/services/engines/probability_engine.dart';

void main() {
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows probabilities for a cash-secured put', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ProbabilityScreen()));
    expect(
      find.text('Enter valid trade details to see probabilities.'),
      findsOneWidget,
    );

    final fields = find.byType(TextField);
    // spot, strike, premium, DTE, IV, risk-free rate.
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '95');
    await tester.enterText(fields.at(2), '1.20');
    await tester.enterText(fields.at(3), '30');
    await tester.enterText(fields.at(4), '30');
    await tester.enterText(fields.at(5), '0');
    await tester.pump();

    expect(find.text('75.8% chance of profit'), findsOneWidget);
    expect(find.text('29.0%'), findsOneWidget);
    expect(find.text('\$93.80'), findsOneWidget);
    expect(find.text('\$120.00'), findsOneWidget);
  });

  testWidgets('spreads ask for a protective strike', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ProbabilityScreen()));
    expect(find.text('Long (protective) strike'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<ProbabilitySide>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Put Credit Spread').last);
    await tester.pumpAndSettle();

    expect(find.text('Long (protective) strike'), findsOneWidget);

    final fields = find.byType(TextField);
    // spot, short strike, long strike, credit, DTE, IV, rate.
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '95');
    await tester.enterText(fields.at(2), '90');
    await tester.enterText(fields.at(3), '1.20');
    await tester.enterText(fields.at(4), '30');
    await tester.enterText(fields.at(5), '30');
    await tester.enterText(fields.at(6), '0');
    await tester.pump();

    expect(find.text('\$380.00'), findsOneWidget);
    expect(find.text('31.6%'), findsOneWidget);
  });
}
