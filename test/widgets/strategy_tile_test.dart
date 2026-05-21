import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riskform/screens/dashboard/strategy_tile.dart';

void main() {
  setUpAll(() {
    // Suppress font loading errors in tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('StrategyTile displays name and reacts to tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StrategyTile(
            name: 'Cash-Secured Put',
            strategyId: 'csp',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Cash-Secured Put'), findsOneWidget);

    await tester.tap(find.byType(StrategyTile));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
