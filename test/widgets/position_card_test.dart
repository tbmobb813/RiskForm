import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/screens/dashboard/position_card.dart';
import 'package:flutter_application_2/models/position.dart';

void main() {
  testWidgets('PositionCard displays symbol, strategy and shows snackbar on tap', (WidgetTester tester) async {
    final pos = Position(
      symbol: 'AAPL',
      strategy: 'CC',
      expiration: DateTime.now().add(const Duration(days: 30)),
      riskFlags: ['High IV'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PositionCard(position: pos)),
      ),
    );

    expect(find.text('AAPL'), findsOneWidget);
    expect(find.text('CC'), findsOneWidget);

    // Tap should trigger SnackBar
    await tester.tap(find.byType(PositionCard));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
