import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/execution/execute_trade_modal.dart';

void main() {
  Future<void> execute(
    WidgetTester tester, {
    required FakeFirebaseFirestore db,
    required String strategyId,
    String? userId,
    String entryPrice = '1.25',
    String contracts = '2',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ExecuteTradeModal.show(
                context,
                planId: 'plan-1',
                strategyId: strategyId,
                firestore: db,
                userId: userId,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Entry Price'), entryPrice);
    await tester.enterText(find.bySemanticsLabel('Contracts'), contracts);
    await tester.tap(find.text('Confirm Execution'));
    await tester.pumpAndSettle();
  }

  Future<void> seedPlan(
    FakeFirebaseFirestore db, {
    Map<String, dynamic> extra = const {},
  }) => db.collection('journalEntries').doc('plan-1').set({
    'createdAt': Timestamp.fromDate(DateTime.now()),
    'strategyId': 'csp',
    'plannedEntryTime': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    'maxEntryPrice': 200,
    'maxRisk': 5,
    'contracts': 2,
    ...extra,
  });

  testWidgets(
    'creates a per-user position with strike, premium and contracts',
    (tester) async {
      final db = FakeFirebaseFirestore();
      final expiration = DateTime.now().add(const Duration(days: 30));
      await seedPlan(
        db,
        extra: {
          'symbol': 'aapl',
          'strike': 50.0,
          'expiration': Timestamp.fromDate(expiration),
        },
      );

      await execute(tester, db: db, strategyId: 'csp', userId: 'user-1');

      final positions = await db
          .collection('users')
          .doc('user-1')
          .collection('positions')
          .get();
      expect(positions.docs.length, 1);
      final data = positions.docs.single.data();
      expect(data['symbol'], 'AAPL');
      expect(data['type'], 'csp');
      expect(data['strike'], 50.0);
      expect(data['premium'], 1.25);
      expect(data['contracts'], 2);
      expect(data['isOpen'], isTrue);

      final journal = await db.collection('journalEntries').doc('plan-1').get();
      expect(journal.data()?['positionId'], positions.docs.single.id);
      expect((await db.collection('positions').get()).docs, isEmpty);
    },
  );

  testWidgets('does not create a position when the plan lacks a symbol', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await seedPlan(
      db,
      extra: {
        'strike': 50.0,
        'expiration': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      },
    );

    await execute(tester, db: db, strategyId: 'csp', userId: 'user-1');

    final positions = await db
        .collection('users')
        .doc('user-1')
        .collection('positions')
        .get();
    expect(positions.docs, isEmpty);
    final journal = await db.collection('journalEntries').doc('plan-1').get();
    expect(journal.data()?['positionId'], isNull);
    expect(journal.data()?['disciplineScore'], isNotNull);
  });

  testWidgets('does not create a position when nobody is signed in', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await seedPlan(
      db,
      extra: {
        'symbol': 'AAPL',
        'strike': 50.0,
        'expiration': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      },
    );

    await execute(tester, db: db, strategyId: 'csp');

    expect((await db.collection('users').get()).docs, isEmpty);
    expect((await db.collection('positions').get()).docs, isEmpty);
    final journal = await db.collection('journalEntries').doc('plan-1').get();
    expect(journal.data()?['disciplineScore'], isNotNull);
  });
}
