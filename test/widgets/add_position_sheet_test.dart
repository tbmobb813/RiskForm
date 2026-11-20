import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/models/position.dart';
import 'package:riskform/screens/capital_allocation/capital_allocation_screen.dart';
import 'package:riskform/screens/dashboard/active_positions_section.dart';
import 'package:riskform/services/data/position_repository.dart';
import 'package:riskform/services/firebase/auth_service.dart';
import 'package:riskform/services/firebase/position_service.dart';
import 'package:riskform/state/account_context_provider.dart';

class _Auth extends AuthService {
  final String? uid;
  _Auth(this.uid) : super.noop();

  @override
  String? get currentUserId => uid;
}

void main() {
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app(
    FakeFirebaseFirestore db,
    String? uid,
    Widget home, {
    bool scrollable = true,
  }) {
    final repo = PositionRepository(PositionService(db), _Auth(uid));
    return ProviderScope(
      overrides: [
        positionRepositoryProvider.overrideWithValue(repo),
        accountContextProvider.overrideWith(
          (ref) async =>
              const AccountContext(accountSize: 10000, buyingPower: 2500),
        ),
      ],
      child: MaterialApp(
        home: scrollable
            ? Scaffold(body: SingleChildScrollView(child: home))
            : home,
      ),
    );
  }

  testWidgets('shows saved positions and records a new one', (tester) async {
    bigScreen(tester);
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(app(db, 'u1', const ActivePositionsSection()));
    await tester.pumpAndSettle();
    expect(find.text('You have no active positions.'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Symbol'),
      'aapl',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Strike'), '50');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Premium / share'),
      '1.25',
    );

    await tester.tap(find.text('Pick expiration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save position'));
    await tester.pumpAndSettle();

    final saved = await db
        .collection('users')
        .doc('u1')
        .collection('positions')
        .get();
    expect(saved.docs.length, 1);
    expect(saved.docs.single.data()['symbol'], 'AAPL');
    expect(saved.docs.single.data()['strike'], 50.0);
    expect(saved.docs.single.data()['premium'], 1.25);
    expect(saved.docs.single.data()['contracts'], 1);

    expect(find.text('AAPL'), findsOneWidget);
    expect(find.text('You have no active positions.'), findsNothing);
  });

  testWidgets('asks the user to sign in when saving signed out', (
    tester,
  ) async {
    bigScreen(tester);
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(app(db, null, const ActivePositionsSection()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Symbol'), 'F');
    await tester.enterText(find.widgetWithText(TextFormField, 'Strike'), '12');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Premium / share'),
      '0.3',
    );
    await tester.tap(find.text('Pick expiration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save position'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to save positions'), findsOneWidget);
    expect((await db.collection('users').get()).docs, isEmpty);
  });

  testWidgets('marks a position closed', (tester) async {
    bigScreen(tester);
    final db = FakeFirebaseFirestore();
    final repo = PositionRepository(PositionService(db), _Auth('u1'));
    await repo.save(
      Position(
        type: PositionType.csp,
        symbol: 'KO',
        strategy: 'CSP',
        quantity: 1,
        isOpen: true,
        expiration: DateTime.now().add(const Duration(days: 20)),
        strike: 60,
        premium: 0.8,
        contracts: 1,
      ),
    );

    await tester.pumpWidget(app(db, 'u1', const ActivePositionsSection()));
    await tester.pumpAndSettle();
    expect(find.text('KO'), findsOneWidget);

    await tester.tap(find.text('Mark closed'));
    await tester.pumpAndSettle();

    expect(find.text('KO'), findsNothing);
    expect(find.text('You have no active positions.'), findsOneWidget);
  });

  testWidgets('allocation screen imports saved positions', (tester) async {
    bigScreen(tester);
    final db = FakeFirebaseFirestore();
    final repo = PositionRepository(PositionService(db), _Auth('u1'));
    await repo.save(
      Position(
        type: PositionType.csp,
        symbol: 'AAPL',
        strategy: 'CSP',
        quantity: 1,
        isOpen: true,
        expiration: DateTime.now().add(const Duration(days: 10, hours: 1)),
        strike: 50,
        premium: 1.0,
        contracts: 1,
        openedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    );

    await tester.pumpWidget(
      app(db, 'u1', const CapitalAllocationScreen(), scrollable: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import open positions'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Imported 1 position'), findsOneWidget);
    expect(find.text('50.0% deployed'), findsOneWidget);
  });
}
