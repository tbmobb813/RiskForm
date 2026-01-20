import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/execution/execute_trade_modal.dart';

void main() {
  testWidgets('ExecuteTradeModal builds and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                // show modal
                ExecuteTradeModal.show(context, planId: 'test', strategyId: 'wheel');
              },
              child: const Text('Open'),
            );
          }),
        ),
      ),
    );

    // Tap the button to open modal
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Execute Trade'), findsOneWidget);
  });
}
