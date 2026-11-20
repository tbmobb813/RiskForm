import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riskform/screens/dashboard/tool_tile.dart';
import 'package:riskform/screens/dashboard/tools_and_strategy_library.dart';
import 'package:riskform/services/firebase/auth_service.dart';

class _Auth extends AuthService {
  final String? uid;
  _Auth(this.uid) : super.noop();

  @override
  String? get currentUserId => uid;
}

Future<void> pump(WidgetTester tester, {String? uid}) async {
  tester.view.physicalSize = const Size(900, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: SingleChildScrollView(child: ToolsAndStrategyLibrary()),
        ),
      ),
      GoRoute(
        path: '/signals',
        name: 'signal_engine',
        builder: (_, _) => const Scaffold(body: Text('SIGNALS PAGE')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(_Auth(uid))],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder tile(String label) => find.widgetWithText(ToolTile, label);
Finder lockOn(String label) =>
    find.descendant(of: tile(label), matching: find.byIcon(Icons.lock));

void main() {
  group('signed out', () {
    testWidgets('the Signal Engine tile looks locked', (tester) async {
      await pump(tester);
      expect(lockOn('Signal Engine'), findsOneWidget);
    });

    testWidgets('tapping it explains why and does not open the engine', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(tile('Signal Engine'));
      await tester.pump();

      expect(find.text('Sign in to use the Signal Engine'), findsOneWidget);
      expect(find.text('SIGNALS PAGE'), findsNothing);
    });

    testWidgets('tools that do not need an account stay unlocked', (
      tester,
    ) async {
      await pump(tester);

      for (final label in ['Best Opps', 'Position Sizing', 'Probability']) {
        expect(tile(label), findsOneWidget, reason: label);
        expect(lockOn(label), findsNothing, reason: label);
      }
    });

    testWidgets('the locked cloud journal tile now shows its message', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(ToolTile, 'Journal (Cloud)'));
      await tester.pump();

      expect(find.text('Sign in to access cloud journal'), findsOneWidget);
    });

    testWidgets('the locked hedge comparison tile now shows its message', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(tile('Hedge Comparison'));
      await tester.pump();

      expect(find.text('Pro feature'), findsOneWidget);
    });
  });

  group('signed in', () {
    testWidgets('the Signal Engine tile is unlocked', (tester) async {
      await pump(tester, uid: 'u1');
      expect(lockOn('Signal Engine'), findsNothing);
    });

    testWidgets('tapping it opens the engine', (tester) async {
      await pump(tester, uid: 'u1');

      await tester.tap(tile('Signal Engine'));
      await tester.pumpAndSettle();

      expect(find.text('SIGNALS PAGE'), findsOneWidget);
      expect(find.text('Sign in to use the Signal Engine'), findsNothing);
    });
  });
}
