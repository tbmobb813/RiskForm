import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/models/analytics/market_regime.dart';
import 'package:riskform/models/analytics/regime_segment.dart';
import 'package:riskform/models/historical/historical_price.dart';
import 'package:riskform/screens/backtest/backtest_screen.dart';
import 'package:riskform/screens/regime_replay/regime_window_picker_screen.dart';
import 'package:riskform/services/historical/regime_window_catalog.dart';
import 'package:riskform/state/account_context_provider.dart';
import 'package:riskform/state/regime_window_providers.dart';

void main() {
  testWidgets(
    'tapping a regime window navigates to BacktestScreen with a matching config',
    (tester) async {
      final baseDate = DateTime(2020, 3, 1);
      final prices = [
        for (int i = 0; i < 30; i++)
          HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0 - i,
            high: 100.0 - i,
            low: 100.0 - i,
            close: 100.0 - i,
            volume: 1000000,
          ),
      ];
      final segment = RegimeSegment(
        regime: MarketRegime.downtrend,
        startDate: prices.first.date,
        endDate: prices.last.date,
        startIndex: 0,
        endIndex: prices.length - 1,
      );
      final catalog = RegimeCatalog(prices: prices, windows: [segment]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            regimeCatalogProvider(
              'SPY',
            ).overrideWith((ref) async => catalog),
            accountContextProvider.overrideWith(
              (ref) async =>
                  const AccountContext(accountSize: 20000, buyingPower: 20000),
            ),
          ],
          child: const MaterialApp(home: RegimeWindowPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Downtrend'), findsOneWidget);

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      final backtestScreenFinder = find.byType(BacktestScreen);
      expect(backtestScreenFinder, findsOneWidget);

      final backtestScreen = tester.widget<BacktestScreen>(
        backtestScreenFinder,
      );
      expect(backtestScreen.config.symbol, 'SPY');
      expect(backtestScreen.config.pricePath.length, prices.length);
      expect(backtestScreen.config.startDate, segment.startDate);
      expect(backtestScreen.config.endDate, segment.endDate);
      expect(backtestScreen.regimeContext?.regime, MarketRegime.downtrend);

      expect(find.textContaining('Replaying SPY'), findsOneWidget);
    },
  );
}
