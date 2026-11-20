import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/screens/csp_screener/csp_screener_screen.dart';
import 'package:riskform/screens/position_sizing/position_sizing_args.dart';
import 'package:riskform/screens/position_sizing/position_sizing_screen.dart';
import 'package:riskform/state/account_context_provider.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CspScreenerScreen()),
        GoRoute(
          path: '/position-sizing',
          name: 'position_sizing',
          builder: (_, state) {
            final args = state.extra as PositionSizingArgs?;
            return PositionSizingScreen(
              initialBuyingPower: args?.buyingPower,
              initialStrike: args?.strike,
              initialPremium: args?.premium,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountContextProvider.overrideWith(
            (ref) async =>
                const AccountContext(accountSize: 10000, buyingPower: 8000),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('screens the example chain and sizes the top pick', (
    tester,
  ) async {
    await pump(tester);

    // Cash per position is prefilled from the account.
    final fields = find.byType(TextField);
    expect(tester.widget<TextField>(fields.at(2)).controller!.text, '8000');

    await tester.tap(find.text('Load example'));
    await tester.pump();
    await tester.enterText(fields.at(2), '10000');
    await tester.tap(find.text('Run screen'));
    await tester.pumpAndSettle();

    expect(find.text('3 candidates · 8 quotes checked'), findsOneWidget);
    final filtered = tester
        .widget<Text>(find.textContaining('Filtered out:'))
        .data!;
    expect(filtered, contains('2 return too low'));
    expect(filtered, contains('1 assignment chance too high'));
    expect(filtered, contains('1 spread too wide or unknown'));
    expect(filtered, contains('1 not a put'));

    // Best annualized return first: the 95 put with 45 days left.
    expect(find.textContaining('\$95 put · 45 DTE'), findsOneWidget);
    expect(find.text('16.2%'), findsOneWidget);
    expect(find.text('27.0% (delta)'), findsOneWidget);

    await tester.tap(find.text('Size this trade').first);
    await tester.pumpAndSettle();

    expect(find.text('Position Sizing'), findsOneWidget);
    final sizing = find.byType(TextField);
    expect(tester.widget<TextField>(sizing.at(0)).controller!.text, '95');
    expect(tester.widget<TextField>(sizing.at(1)).controller!.text, '1.90');
    expect(tester.widget<TextField>(sizing.at(3)).controller!.text, '10000');
  });

  testWidgets('asks for the stock price and cash before running', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Run screen'));
    await tester.pump();
    expect(find.text('Enter the current stock price.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.enterText(find.byType(TextField).at(2), '0');
    await tester.tap(find.text('Run screen'));
    await tester.pump();
    expect(
      find.text('Enter the cash you can use per position.'),
      findsOneWidget,
    );
  });

  testWidgets('explains a chain it cannot read', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField).at(0), 'foo,bar\n1,2');
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.tap(find.text('Run screen'));
    await tester.pumpAndSettle();

    expect(find.text('Could not read 1 line(s)'), findsOneWidget);
    expect(find.textContaining('Header row is missing'), findsOneWidget);
    expect(find.textContaining('candidate'), findsNothing);
  });

  testWidgets('says so when nothing passes the filters', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Load example'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(2), '10000');
    // Demand more than any example quote delivers.
    await tester.enterText(find.byType(TextField).at(6), '90');
    await tester.tap(find.text('Run screen'));
    await tester.pumpAndSettle();

    expect(find.text('0 candidates · 8 quotes checked'), findsOneWidget);
    expect(find.text('Size this trade'), findsNothing);
  });
}
