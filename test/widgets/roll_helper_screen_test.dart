import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/screens/roll_helper/roll_helper_screen.dart';

void main() {
  testWidgets('shows a roll verdict after entering a profitable roll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: RollHelperScreen()));
    expect(find.text('Enter valid position and candidate details.'), findsOne);

    final fields = find.byType(TextField);
    // Position: strike, DTE, stock, buyback, original premium, buying power.
    await tester.enterText(fields.at(0), '50');
    await tester.enterText(fields.at(1), '5');
    await tester.enterText(fields.at(2), '47');
    await tester.enterText(fields.at(3), '3.50');
    await tester.enterText(fields.at(4), '1.00');
    // Candidate: strike, DTE, credit.
    await tester.enterText(fields.at(6), '47');
    await tester.enterText(fields.at(7), '60');
    await tester.enterText(fields.at(8), '4.20');
    await tester.pump();

    expect(find.text('Roll'), findsOneWidget);
    expect(find.textContaining('(best)'), findsOneWidget);
    expect(find.text('+\$0.70'), findsOneWidget);
    expect(find.text('\$45.30'), findsOneWidget);
  });

  testWidgets('add and remove candidate rows', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: RollHelperScreen()));
    expect(find.text('New strike'), findsOneWidget);

    await tester.tap(find.text('Add candidate'));
    await tester.pump();
    expect(find.text('New strike'), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();
    expect(find.text('New strike'), findsOneWidget);
  });
}
