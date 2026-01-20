import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/screens/dashboard/strategy_tile.dart';

void main() {
  testWidgets('StrategyTile displays texts and reacts to tap', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StrategyTile(
            name: 'Test Strategy',
            category: 'Income',
            color: Colors.green,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    // Verify texts
    expect(find.text('Test Strategy'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    // Tap and verify callback
    await tester.tap(find.byType(StrategyTile));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
