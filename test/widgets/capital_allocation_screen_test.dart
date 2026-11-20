import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/screens/capital_allocation/capital_allocation_screen.dart';
import 'package:riskform/screens/position_sizing/position_sizing_args.dart';
import 'package:riskform/screens/position_sizing/position_sizing_screen.dart';
import 'package:riskform/state/account_context_provider.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountContextProvider.overrideWith(
            (ref) async =>
                const AccountContext(accountSize: 10000, buyingPower: 2500),
          ),
        ],
        child: const MaterialApp(home: CapitalAllocationScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prefills account and summarizes a concentrated position', (
    tester,
  ) async {
    await pump(tester);

    final fields = find.byType(TextField);
    // account, free cash, yield, max per symbol, then the first position:
    // symbol, capital, premium, days in trade, DTE.
    expect(tester.widget<TextField>(fields.at(0)).controller!.text, '10000');
    expect(tester.widget<TextField>(fields.at(1)).controller!.text, '2500');

    await tester.enterText(fields.at(4), 'aapl');
    await tester.enterText(fields.at(5), '5000');
    await tester.enterText(fields.at(6), '100');
    await tester.enterText(fields.at(8), '10');
    await tester.pump();

    expect(find.text('50.0% deployed'), findsOneWidget);
    expect(find.text('\$2500'), findsWidgets);
    expect(find.textContaining('AAPL is 50%'), findsOneWidget);
    expect(find.text('Within 14 days'), findsOneWidget);
  });

  testWidgets('sends the next-trade budget to position sizing', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CapitalAllocationScreen()),
        GoRoute(
          path: '/position-sizing',
          name: 'position_sizing',
          builder: (_, state) => PositionSizingScreen(
            initialBuyingPower:
                (state.extra as PositionSizingArgs?)?.buyingPower,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountContextProvider.overrideWith(
            (ref) async =>
                const AccountContext(accountSize: 10000, buyingPower: 2500),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '1800');
    await tester.pump();
    await tester.tap(find.text('Size a trade with this budget'));
    await tester.pumpAndSettle();

    expect(find.text('Position Sizing'), findsOneWidget);
    final fields = find.byType(TextField);
    expect(tester.widget<TextField>(fields.at(3)).controller!.text, '1800');
  });

  testWidgets('add and remove positions', (tester) async {
    await pump(tester);
    expect(find.text('Symbol'), findsOneWidget);

    await tester.tap(find.text('Add position'));
    await tester.pump();
    expect(find.text('Symbol'), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();
    expect(find.text('Symbol'), findsOneWidget);
  });
}
