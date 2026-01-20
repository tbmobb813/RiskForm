import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riskform/execution/execute_trade_modal.dart';

void main() {
  testWidgets('ExecuteTradeModal writes discipline score to journal (mock firestore)', (WidgetTester tester) async {
    final mock = FakeFirebaseFirestore();

    // create a minimal planned journal entry
    final doc = mock.collection('journalEntries').doc('plan-test');
    await doc.set({
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'strategyId': 'wheel',
      'plannedEntryTime': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 10))),
      'maxEntryPrice': 200,
      'maxRisk': 5,
      'contracts': 1,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                ExecuteTradeModal.show(context, planId: 'plan-test', strategyId: 'wheel', firestore: mock);
              },
              child: const Text('Open'),
            );
          }),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // fill form
    await tester.enterText(find.bySemanticsLabel('Entry Price'), '100');
    await tester.enterText(find.bySemanticsLabel('Contracts'), '1');
    await tester.tap(find.text('Confirm Execution'));

    // allow async writes
    await tester.pumpAndSettle();

    final updated = await mock.collection('journalEntries').doc('plan-test').get();
    expect(updated.exists, isTrue);
    expect(updated.data()?['disciplineScore'], isNotNull);
    expect(updated.data()?['disciplineBreakdown'], isNotNull);
  });
}
