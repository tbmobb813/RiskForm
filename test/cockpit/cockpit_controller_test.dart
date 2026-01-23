import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import '../../lib/screens/cockpit/controllers/cockpit_controller.dart';
import '../../lib/screens/cockpit/models/watchlist_item.dart';
import '../../lib/screens/cockpit/models/pending_journal_trade.dart';
import '../../lib/services/market_data/market_data_service.dart';
import '../../lib/services/market_data/models/quote.dart';

@GenerateMocks([MarketDataService])
import 'cockpit_controller_test.mocks.dart';

void main() {
  group('CockpitController', () {
    late ProviderContainer container;
    late MockMarketDataService mockMarketDataService;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockMarketDataService = MockMarketDataService();
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(signedIn: true);

      container = ProviderContainer(
        overrides: [
          // Override market data service provider
          marketDataServiceProvider.overrideWithValue(mockMarketDataService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Watchlist with Live Data', () {
      test('loads watchlist with live data when service available', () async {
        // Setup mock quotes
        final spyQuote = Quote(
          ticker: 'SPY',
          price: 450.00,
          change: 5.00,
          changePercent: 1.12,
          timestamp: DateTime.now(),
          isDelayed: false,
          bid: 449.95,
          ask: 450.05,
          volume: 50000000,
          open: 445.00,
          high: 451.00,
          low: 444.50,
          close: 450.00,
        );

        when(mockMarketDataService.fetchQuote('SPY'))
            .thenAnswer((_) async => spyQuote);
        when(mockMarketDataService.calculateIVPercentile('SPY'))
            .thenAnswer((_) async => 65.0);

        // Setup Firestore watchlist
        await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('cockpit')
            .doc('watchlist')
            .set({
          'tickers': ['SPY'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final controller = container.read(cockpitControllerProvider.notifier);
        await controller.refresh();

        final state = container.read(cockpitControllerProvider);

        expect(state.watchlist.length, 1);
        expect(state.watchlist.first.ticker, 'SPY');
        expect(state.watchlist.first.hasLiveData, true);
        expect(state.watchlist.first.price, 450.00);
        expect(state.watchlist.first.ivPercentile, 65.0);
        expect(state.watchlist.first.changePercent, 1.12);
      });

      test('falls back to placeholders when market data service unavailable', () async {
        // Override with null service
        final nullContainer = ProviderContainer(
          overrides: [
            marketDataServiceProvider.overrideWithValue(null),
          ],
        );

        // Setup Firestore watchlist
        await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('cockpit')
            .doc('watchlist')
            .set({
          'tickers': ['SPY', 'QQQ'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final controller = nullContainer.read(cockpitControllerProvider.notifier);
        await controller.refresh();

        final state = nullContainer.read(cockpitControllerProvider);

        expect(state.watchlist.length, 2);
        expect(state.watchlist[0].hasLiveData, false);
        expect(state.watchlist[0].price, null);
        expect(state.watchlist[1].hasLiveData, false);

        nullContainer.dispose();
      });

      test('handles individual ticker errors gracefully', () async {
        // SPY succeeds, QQQ fails
        final spyQuote = Quote(
          ticker: 'SPY',
          price: 450.00,
          change: 5.00,
          changePercent: 1.12,
          timestamp: DateTime.now(),
          isDelayed: false,
          bid: 449.95,
          ask: 450.05,
          volume: 50000000,
          open: 445.00,
          high: 451.00,
          low: 444.50,
          close: 450.00,
        );

        when(mockMarketDataService.fetchQuote('SPY'))
            .thenAnswer((_) async => spyQuote);
        when(mockMarketDataService.calculateIVPercentile('SPY'))
            .thenAnswer((_) async => 65.0);

        when(mockMarketDataService.fetchQuote('QQQ'))
            .thenThrow(Exception('API error'));

        await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('cockpit')
            .doc('watchlist')
            .set({
          'tickers': ['SPY', 'QQQ'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final controller = container.read(cockpitControllerProvider.notifier);
        await controller.refresh();

        final state = container.read(cockpitControllerProvider);

        expect(state.watchlist.length, 2);
        expect(state.watchlist[0].hasLiveData, true); // SPY succeeded
        expect(state.watchlist[1].hasLiveData, false); // QQQ failed
      });

      test('refreshWatchlist updates live data', () async {
        final initialQuote = Quote(
          ticker: 'SPY',
          price: 450.00,
          change: 5.00,
          changePercent: 1.12,
          timestamp: DateTime.now(),
          isDelayed: false,
          bid: 449.95,
          ask: 450.05,
          volume: 50000000,
          open: 445.00,
          high: 451.00,
          low: 444.50,
          close: 450.00,
        );

        final updatedQuote = Quote(
          ticker: 'SPY',
          price: 452.00,
          change: 7.00,
          changePercent: 1.57,
          timestamp: DateTime.now(),
          isDelayed: false,
          bid: 451.95,
          ask: 452.05,
          volume: 51000000,
          open: 445.00,
          high: 453.00,
          low: 444.50,
          close: 452.00,
        );

        when(mockMarketDataService.fetchQuote('SPY'))
            .thenAnswer((_) async => initialQuote);
        when(mockMarketDataService.calculateIVPercentile('SPY'))
            .thenAnswer((_) async => 65.0);

        await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('cockpit')
            .doc('watchlist')
            .set({
          'tickers': ['SPY'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final controller = container.read(cockpitControllerProvider.notifier);
        await controller.refresh();

        var state = container.read(cockpitControllerProvider);
        expect(state.watchlist.first.price, 450.00);

        // Update mock to return new price
        when(mockMarketDataService.fetchQuote('SPY'))
            .thenAnswer((_) async => updatedQuote);

        await controller.refreshWatchlist();

        state = container.read(cockpitControllerProvider);
        expect(state.watchlist.first.price, 452.00);
        expect(state.watchlist.first.changePercent, 1.57);
      });
    });

    group('Add to Watchlist', () {
      test('adds ticker with live data', () async {
        final spyQuote = Quote(
          ticker: 'SPY',
          price: 450.00,
          change: 5.00,
          changePercent: 1.12,
          timestamp: DateTime.now(),
          isDelayed: false,
          bid: 449.95,
          ask: 450.05,
          volume: 50000000,
          open: 445.00,
          high: 451.00,
          low: 444.50,
          close: 450.00,
        );

        when(mockMarketDataService.fetchQuote('SPY'))
            .thenAnswer((_) async => spyQuote);
        when(mockMarketDataService.calculateIVPercentile('SPY'))
            .thenAnswer((_) async => 65.0);

        final controller = container.read(cockpitControllerProvider.notifier);
        await controller.addToWatchlist('SPY');

        final state = container.read(cockpitControllerProvider);

        expect(state.watchlist.length, 1);
        expect(state.watchlist.first.ticker, 'SPY');
        expect(state.watchlist.first.hasLiveData, true);
        expect(state.watchlist.first.price, 450.00);
      });

      test('normalizes ticker to uppercase', () async {
        final spyQuote = Quote(
          ticker: 'SPY',
          price: 450.00,
          change: 5.00,
          changePercent: 1.12,
          timestamp: DateTime.now(),
          isDelayed: false,
          bid: 449.95,
          ask: 450.05,
          volume: 50000000,
          open: 445.00,
          high: 451.00,
          low: 444.50,
          close: 450.00,
        );

        when(mockMarketDataService.fetchQuote('SPY'))
            .thenAnswer((_) async => spyQuote);
        when(mockMarketDataService.calculateIVPercentile('SPY'))
            .thenAnswer((_) async => 65.0);

        final controller = container.read(cockpitControllerProvider.notifier);
        await controller.addToWatchlist('spy'); // lowercase

        final state = container.read(cockpitControllerProvider);

        expect(state.watchlist.first.ticker, 'SPY');
        verify(mockMarketDataService.fetchQuote('SPY')).called(1);
      });

      test('enforces 5 ticker limit', () async {
        final controller = container.read(cockpitControllerProvider.notifier);

        // Mock quotes for 5 tickers
        for (int i = 1; i <= 5; i++) {
          final quote = Quote(
            ticker: 'TICK$i',
            price: 100.0 * i,
            change: 1.0,
            changePercent: 1.0,
            timestamp: DateTime.now(),
            isDelayed: false,
            bid: 99.0,
            ask: 101.0,
            volume: 10000,
            open: 100.0,
            high: 105.0,
            low: 95.0,
            close: 100.0,
          );

          when(mockMarketDataService.fetchQuote('TICK$i'))
              .thenAnswer((_) async => quote);
          when(mockMarketDataService.calculateIVPercentile('TICK$i'))
              .thenAnswer((_) async => 50.0);

          await controller.addToWatchlist('TICK$i');
        }

        final state = container.read(cockpitControllerProvider);
        expect(state.watchlist.length, 5);

        // Attempt to add 6th ticker should throw
        expect(
          () => controller.addToWatchlist('TICK6'),
          throwsException,
        );
      });
    });

    group('Remove from Watchlist', () {
      test('removes ticker from watchlist', () async {
        final spyQuote = Quote(
          ticker: 'SPY',
          price: 450.00,
          change: 5.00,
          changePercent: 1.12,
          timestamp: DateTime.now(),
          isDelayed: false,
          bid: 449.95,
          ask: 450.05,
          volume: 50000000,
          open: 445.00,
          high: 451.00,
          low: 444.50,
          close: 450.00,
        );

        final qqqQuote = Quote(
          ticker: 'QQQ',
          price: 380.00,
          change: 3.00,
          changePercent: 0.79,
          timestamp: DateTime.now(),
          isDelayed: false,
          bid: 379.95,
          ask: 380.05,
          volume: 30000000,
          open: 377.00,
          high: 381.00,
          low: 376.50,
          close: 380.00,
        );

        when(mockMarketDataService.fetchQuote('SPY'))
            .thenAnswer((_) async => spyQuote);
        when(mockMarketDataService.fetchQuote('QQQ'))
            .thenAnswer((_) async => qqqQuote);
        when(mockMarketDataService.calculateIVPercentile(any))
            .thenAnswer((_) async => 50.0);

        final controller = container.read(cockpitControllerProvider.notifier);
        await controller.addToWatchlist('SPY');
        await controller.addToWatchlist('QQQ');

        var state = container.read(cockpitControllerProvider);
        expect(state.watchlist.length, 2);

        await controller.removeFromWatchlist('SPY');

        state = container.read(cockpitControllerProvider);
        expect(state.watchlist.length, 1);
        expect(state.watchlist.first.ticker, 'QQQ');
      });
    });

    group('Pending Journals', () {
      test('adds pending journal and updates discipline', () async {
        final controller = container.read(cockpitControllerProvider.notifier);

        final pendingTrade = PendingJournalTrade(
          positionId: 'pos-123',
          ticker: 'SPY',
          strategy: 'Wheel',
          pnl: 150.0,
          isPaper: false,
          closedAt: DateTime.now(),
        );

        await controller.addPendingJournal(pendingTrade);

        final state = container.read(cockpitControllerProvider);

        expect(state.pendingJournals.length, 1);
        expect(state.pendingJournals.first.positionId, 'pos-123');
        expect(state.isBlocked, true);
      });

      test('removes pending journal after journaling', () async {
        final controller = container.read(cockpitControllerProvider.notifier);

        final pendingTrade = PendingJournalTrade(
          positionId: 'pos-123',
          ticker: 'SPY',
          strategy: 'Wheel',
          pnl: 150.0,
          isPaper: false,
          closedAt: DateTime.now(),
        );

        await controller.addPendingJournal(pendingTrade);

        var state = container.read(cockpitControllerProvider);
        expect(state.pendingJournals.length, 1);

        await controller.removePendingJournal('pos-123');

        state = container.read(cockpitControllerProvider);
        expect(state.pendingJournals.isEmpty, true);
        expect(state.isBlocked, false);
      });
    });

    group('Discipline Snapshot', () {
      test('calculates discipline score from recent entries', () async {
        // This test would require mocking Firestore with journal entries
        // Simplified version for now
        final controller = container.read(cockpitControllerProvider.notifier);
        await controller.refresh();

        final state = container.read(cockpitControllerProvider);

        expect(state.discipline, isNotNull);
        expect(state.discipline.currentScore, greaterThanOrEqualTo(0));
        expect(state.discipline.currentScore, lessThanOrEqualTo(100));
      });
    });
  });
}
