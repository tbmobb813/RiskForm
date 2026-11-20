import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/screens/pmcc/pmcc_screen.dart';

void main() {
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> fill(WidgetTester tester, {String shortStrike = '105'}) async {
    final f = find.byType(TextField);
    // spot, LEAPS strike, cost, DTE, delta, short strike, credit, DTE, premiums.
    await tester.enterText(f.at(0), '100');
    await tester.enterText(f.at(1), '70');
    await tester.enterText(f.at(2), '34');
    await tester.enterText(f.at(3), '400');
    await tester.enterText(f.at(4), '0.85');
    await tester.enterText(f.at(5), shortStrike);
    await tester.enterText(f.at(6), '1.5');
    await tester.enterText(f.at(7), '30');
    await tester.enterText(f.at(8), '5');
    await tester.pump();
  }

  testWidgets('shows cost basis and profit for a valid setup', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: PmccScreen()));
    expect(find.textContaining('Enter valid details'), findsOneWidget);

    await fill(tester);

    expect(find.text('\$104.00'), findsOneWidget); // synthetic stock cost
    expect(find.text('\$97.50'), findsOneWidget); // effective basis
    expect(
      find.text('\$750.00'),
      findsOneWidget,
    ); // best-case profit / contract
    expect(find.text('66.0%'), findsOneWidget); // capital saved
    expect(find.textContaining('Enter valid details'), findsNothing);
  });

  testWidgets('warns when the strike gap cannot cover the cost', (
    tester,
  ) async {
    bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: PmccScreen()));

    await fill(tester, shortStrike: '95');

    expect(find.textContaining('lose money'), findsOneWidget);
  });

  testWidgets('rejects a short call at or below the LEAPS strike', (
    tester,
  ) async {
    bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: PmccScreen()));

    await fill(tester, shortStrike: '65');

    expect(find.textContaining('Enter valid details'), findsOneWidget);
  });
}
