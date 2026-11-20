import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/screens/csp_screener/csp_screener_screen.dart';
import 'package:riskform/screens/position_sizing/position_sizing_args.dart';
import 'package:riskform/screens/position_sizing/position_sizing_screen.dart';
import 'package:riskform/services/options/option_chain.dart';
import 'package:riskform/services/options/tradier_chain_source.dart';
import 'package:riskform/state/account_context_provider.dart';

Finder field(String label) => find.widgetWithText(TextField, label);

/// A live snapshot built relative to now so days to expiration stay fixed.
ChainSnapshot liveSnapshot({
  String symbol = 'XYZ',
  double spot = 100,
  bool empty = false,
}) {
  final asOf = DateTime.now();
  final expiration = DateTime.utc(asOf.year, asOf.month, asOf.day + 30);
  OptionQuote put(double strike, double bid, double ask, double delta) =>
      OptionQuote(
        right: OptionRight.put,
        strike: strike,
        expiration: expiration,
        bid: bid,
        ask: ask,
        delta: delta,
        openInterest: 500,
      );
  return ChainSnapshot(
    underlying: symbol,
    spot: spot,
    asOf: asOf,
    quotes: empty
        ? const []
        : [
            put(95, 1.20, 1.30, 0.25), // passes: 15.4% annualized
            put(90, 0.50, 0.55, 0.12), // return too low
            put(98, 2.40, 2.60, 0.38), // assignment chance too high
          ],
  );
}

void main() {
  Future<void> pump(WidgetTester tester, {LiveChainFetcher? fetcher}) async {
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
          if (fetcher != null)
            liveChainFetcherProvider.overrideWithValue(fetcher),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  String textIn(WidgetTester tester, Finder f) =>
      tester.widget<TextField>(f).controller!.text;

  group('pasted chains', () {
    testWidgets('screens the example chain and sizes the top pick', (
      tester,
    ) async {
      await pump(tester);

      // Cash per position is prefilled from the account.
      expect(textIn(tester, field(r'Cash per position ($)')), '8000');

      await tester.tap(find.text('Load example'));
      await tester.pump();
      await tester.enterText(field(r'Cash per position ($)'), '10000');
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
      expect(find.textContaining(r'$95 put · 45 DTE'), findsOneWidget);
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

      await tester.enterText(field('Stock price'), '100');
      await tester.enterText(field(r'Cash per position ($)'), '0');
      await tester.tap(find.text('Run screen'));
      await tester.pump();
      expect(
        find.text('Enter the cash you can use per position.'),
        findsOneWidget,
      );
    });

    testWidgets('explains a chain it cannot read', (tester) async {
      await pump(tester);

      await tester.enterText(field('Option chain'), 'foo,bar\n1,2');
      await tester.enterText(field('Stock price'), '100');
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
      await tester.enterText(field(r'Cash per position ($)'), '10000');
      // Demand more than any example quote delivers.
      await tester.enterText(field('Min annualized %'), '90');
      await tester.tap(find.text('Run screen'));
      await tester.pumpAndSettle();

      expect(find.text('0 candidates · 8 quotes checked'), findsOneWidget);
      expect(find.text('Size this trade'), findsNothing);
    });
  });

  group('live data', () {
    testWidgets('fetches a chain, fills the price and screens it', (
      tester,
    ) async {
      String? asked;
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async {
          asked = symbol;
          return liveSnapshot(spot: 101.25);
        },
      );

      await tester.enterText(field('Stock symbol'), 'xyz');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pumpAndSettle();

      expect(asked, 'XYZ');
      expect(textIn(tester, field('Stock price')), '101.25');
      expect(
        find.textContaining('Using the live chain for XYZ: 3 quotes'),
        findsOneWidget,
      );

      await tester.enterText(field(r'Cash per position ($)'), '10000');
      await tester.tap(find.text('Run screen'));
      await tester.pumpAndSettle();

      expect(find.text('1 candidate · 3 quotes checked'), findsOneWidget);
      expect(find.textContaining(r'$95 put · 30 DTE'), findsOneWidget);
      expect(find.textContaining('Could not read'), findsNothing);
    });

    testWidgets('asks for the expiration window you set', (tester) async {
      int? gotMin;
      int? gotMax;
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async {
          gotMin = minDte;
          gotMax = maxDte;
          return liveSnapshot();
        },
      );

      await tester.enterText(field('Min DTE'), '14');
      await tester.enterText(field('Max DTE'), '45');
      await tester.enterText(field('Stock symbol'), 'XYZ');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pumpAndSettle();

      expect([gotMin, gotMax], [14, 45]);
      expect(find.textContaining('(14-45 DTE)'), findsOneWidget);
    });

    testWidgets('shows the reason when the fetch fails', (tester) async {
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async =>
            throw const LiveChainException('Sign in to load live data.'),
      );

      await tester.enterText(field('Stock symbol'), 'XYZ');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to load live data.'), findsOneWidget);
      expect(find.textContaining('Using the live chain'), findsNothing);
    });

    testWidgets('handles an unexpected failure with a plain message', (
      tester,
    ) async {
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async =>
            throw StateError('boom'),
      );

      await tester.enterText(field('Stock symbol'), 'XYZ');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load live data.'), findsOneWidget);
    });

    testWidgets('asks for a symbol before fetching', (tester) async {
      var calls = 0;
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async {
          calls++;
          return liveSnapshot();
        },
      );

      await tester.tap(find.text('Fetch live chain'));
      await tester.pump();

      expect(find.text('Enter a stock symbol.'), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('disables the button while fetching', (tester) async {
      final pending = Completer<ChainSnapshot>();
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) => pending.future,
      );

      await tester.enterText(field('Stock symbol'), 'XYZ');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pump();

      expect(find.text('Fetching...'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Fetching...'),
      );
      expect(button.onPressed, isNull);

      pending.complete(liveSnapshot());
      await tester.pumpAndSettle();

      expect(find.text('Fetch live chain'), findsOneWidget);
    });

    testWidgets('switches back to pasted data when you load or edit it', (
      tester,
    ) async {
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async => liveSnapshot(),
      );

      await tester.enterText(field('Stock symbol'), 'XYZ');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Using the live chain'), findsOneWidget);

      await tester.tap(find.text('Load example'));
      await tester.pump();
      expect(find.textContaining('Using the live chain'), findsNothing);

      await tester.enterText(field(r'Cash per position ($)'), '10000');
      await tester.tap(find.text('Run screen'));
      await tester.pumpAndSettle();
      // The pasted example has 8 quotes; the live snapshot had 3.
      expect(find.text('3 candidates · 8 quotes checked'), findsOneWidget);
    });

    testWidgets('editing the pasted text drops the live chain', (tester) async {
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async => liveSnapshot(),
      );

      await tester.enterText(field('Stock symbol'), 'XYZ');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Using the live chain'), findsOneWidget);

      await tester.enterText(field('Option chain'), 'strike,bid,dte\n95,1,30');
      await tester.pump();

      expect(find.textContaining('Using the live chain'), findsNothing);
    });

    testWidgets('warns when your range is wider than what was fetched', (
      tester,
    ) async {
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async => liveSnapshot(),
      );

      await tester.enterText(field('Stock symbol'), 'XYZ');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pumpAndSettle();
      expect(find.textContaining('fetch again'), findsNothing);

      await tester.enterText(field('Max DTE'), '90');
      await tester.pump();

      expect(find.textContaining('fetch again'), findsOneWidget);
    });

    testWidgets('explains an empty live chain', (tester) async {
      await pump(
        tester,
        fetcher: (symbol, {minDte = 21, maxDte = 60}) async =>
            liveSnapshot(empty: true),
      );

      await tester.enterText(field('Stock symbol'), 'XYZ');
      await tester.tap(find.text('Fetch live chain'));
      await tester.pumpAndSettle();
      await tester.enterText(field(r'Cash per position ($)'), '10000');
      await tester.tap(find.text('Run screen'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'The live chain has no quotes in that expiration range',
        ),
        findsOneWidget,
      );
    });
  });
}
