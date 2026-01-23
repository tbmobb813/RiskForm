import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/market_data/market_data_service.dart';
import '../../lib/services/market_data/adapters/market_data_adapter.dart';
import '../../lib/services/market_data/models/quote.dart';
import '../../lib/services/market_data/models/options_chain.dart';
import '../../lib/services/market_data/models/option_contract.dart';
import '../../lib/services/market_data/models/greeks.dart';

@GenerateMocks([MarketDataAdapter])
import 'market_data_service_test.mocks.dart';

void main() {
  group('MarketDataService', () {
    late MarketDataService service;
    late MockMarketDataAdapter mockAdapter;

    setUp(() {
      mockAdapter = MockMarketDataAdapter();
      service = MarketDataService(adapter: mockAdapter);
    });

    group('fetchQuote', () {
      test('returns quote from adapter', () async {
        final expectedQuote = Quote(
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

        when(mockAdapter.fetchQuote('SPY'))
            .thenAnswer((_) async => expectedQuote);

        final quote = await service.fetchQuote('SPY');

        expect(quote.ticker, 'SPY');
        expect(quote.price, 450.00);
        expect(quote.changePercent, 1.12);
        verify(mockAdapter.fetchQuote('SPY')).called(1);
      });

      test('uses cache on second call within TTL', () async {
        final quote = Quote(
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

        when(mockAdapter.fetchQuote('SPY'))
            .thenAnswer((_) async => quote);

        // First call
        await service.fetchQuote('SPY');

        // Second call (should use cache)
        await service.fetchQuote('SPY');

        // Adapter should only be called once
        verify(mockAdapter.fetchQuote('SPY')).called(1);
      });

      test('returns placeholder on error', () async {
        when(mockAdapter.fetchQuote('INVALID'))
            .thenThrow(Exception('Not found'));

        final quote = await service.fetchQuote('INVALID');

        expect(quote.ticker, 'INVALID');
        expect(quote.price, 0.0);
        expect(quote.isDelayed, true);
      });

      test('normalizes ticker to uppercase', () async {
        final quote = Quote(
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

        when(mockAdapter.fetchQuote('SPY'))
            .thenAnswer((_) async => quote);

        await service.fetchQuote('spy');

        verify(mockAdapter.fetchQuote('SPY')).called(1);
      });
    });

    group('fetchQuotes', () {
      test('fetches multiple quotes', () async {
        final quotes = [
          Quote(
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
          ),
          Quote(
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
          ),
        ];

        when(mockAdapter.supportsBatch).thenReturn(true);
        when(mockAdapter.fetchQuotesBatch(['SPY', 'QQQ']))
            .thenAnswer((_) async => quotes);

        final result = await service.fetchQuotes(['SPY', 'QQQ']);

        expect(result.length, 2);
        expect(result[0].ticker, 'SPY');
        expect(result[1].ticker, 'QQQ');
      });

      test('falls back to individual calls if batch not supported', () async {
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

        when(mockAdapter.supportsBatch).thenReturn(false);
        when(mockAdapter.fetchQuote('SPY')).thenAnswer((_) async => spyQuote);
        when(mockAdapter.fetchQuote('QQQ')).thenAnswer((_) async => qqqQuote);

        final result = await service.fetchQuotes(['SPY', 'QQQ']);

        expect(result.length, 2);
        verify(mockAdapter.fetchQuote('SPY')).called(1);
        verify(mockAdapter.fetchQuote('QQQ')).called(1);
      });
    });

    group('fetchOptionsChain', () {
      test('returns options chain from adapter', () async {
        final chain = OptionsChain(
          ticker: 'SPY',
          calls: [
            OptionContract(
              symbol: 'SPY240119C00450000',
              strike: 450.0,
              type: OptionType.call,
              expiration: DateTime(2024, 1, 19),
              bid: 5.00,
              ask: 5.10,
              last: 5.05,
              volume: 1000,
              openInterest: 5000,
              greeks: Greeks(
                delta: 0.50,
                gamma: 0.02,
                theta: -0.05,
                vega: 0.10,
                rho: 0.01,
                iv: 0.20,
              ),
            ),
          ],
          puts: [],
        );

        when(mockAdapter.fetchOptionsChain('SPY'))
            .thenAnswer((_) async => chain);

        final result = await service.fetchOptionsChain('SPY');

        expect(result.ticker, 'SPY');
        expect(result.calls.length, 1);
        expect(result.calls.first.strike, 450.0);
      });

      test('uses cache on second call', () async {
        final chain = OptionsChain(
          ticker: 'SPY',
          calls: [],
          puts: [],
        );

        when(mockAdapter.fetchOptionsChain('SPY'))
            .thenAnswer((_) async => chain);

        await service.fetchOptionsChain('SPY');
        await service.fetchOptionsChain('SPY');

        verify(mockAdapter.fetchOptionsChain('SPY')).called(1);
      });

      test('returns empty chain on error', () async {
        when(mockAdapter.fetchOptionsChain('INVALID'))
            .thenThrow(Exception('Not found'));

        final result = await service.fetchOptionsChain('INVALID');

        expect(result.ticker, 'INVALID');
        expect(result.calls.isEmpty, true);
        expect(result.puts.isEmpty, true);
      });
    });

    group('calculateIVPercentile', () {
      test('returns IV percentile', () async {
        // This is a simplified test - real implementation would fetch historical IV
        final result = await service.calculateIVPercentile('SPY');

        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(100));
      });

      test('returns 0 on error', () async {
        when(mockAdapter.fetchOptionsChain('INVALID'))
            .thenThrow(Exception('Not found'));

        final result = await service.calculateIVPercentile('INVALID');

        expect(result, 0.0);
      });
    });

    group('health checks', () {
      test('reports healthy when adapter responds', () async {
        final quote = Quote(
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

        when(mockAdapter.fetchQuote('SPY'))
            .thenAnswer((_) async => quote);

        final isHealthy = await service.healthCheck();

        expect(isHealthy, true);
      });

      test('reports unhealthy when adapter fails', () async {
        when(mockAdapter.fetchQuote('SPY'))
            .thenThrow(Exception('Service unavailable'));

        final isHealthy = await service.healthCheck();

        expect(isHealthy, false);
      });
    });
  });
}
