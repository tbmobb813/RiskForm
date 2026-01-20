import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/historical/historical_repository.dart';
import 'package:riskform/services/historical/historical_cache.dart';
import 'package:riskform/models/historical/historical_price.dart';
import '../fakes/fake_historical_data_source.dart';
import '../fakes/fake_box.dart';

void main() {
  group('HistoricalRepository', () {
    late FakeHistoricalDataSource fakeSource;
    late HistoricalCache cache;
    late FakeBox fakeBox;
    late HistoricalRepository repository;

    setUp(() {
      fakeSource = FakeHistoricalDataSource();
      fakeBox = FakeBox();
      cache = HistoricalCache(fakeBox);
      repository = HistoricalRepository(
        source: fakeSource,
        cache: cache,
      );
    });

    group('Successful Fetches', () {
      test('should fetch prices from source when cache is empty', () async {
        // Arrange
        final symbol = 'AAPL';
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);
        final mockPrices = [
          HistoricalPrice(
            date: DateTime(2025, 1, 1),
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 154.0,
            volume: 1000000.0,
          ),
          HistoricalPrice(
            date: DateTime(2025, 1, 2),
            open: 154.0,
            high: 156.0,
            low: 153.0,
            close: 155.5,
            volume: 1100000.0,
          ),
        ];
        fakeSource.mockResponse = mockPrices;

        // Act
        final result = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Assert
        expect(result, equals(mockPrices));
        expect(fakeSource.fetchCallCount, equals(1));
      });

      test('should return fetched prices with correct data', () async {
        // Arrange
        final symbol = 'TSLA';
        final start = DateTime(2025, 2, 1);
        final end = DateTime(2025, 2, 5);
        final mockPrices = [
          HistoricalPrice(
            date: DateTime(2025, 2, 1),
            open: 200.0,
            high: 210.0,
            low: 198.0,
            close: 205.0,
            volume: 2000000.0,
          ),
        ];
        fakeSource.mockResponse = mockPrices;

        // Act
        final result = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Assert
        expect(result.length, equals(1));
        expect(result[0].date, equals(DateTime(2025, 2, 1)));
        expect(result[0].open, equals(200.0));
        expect(result[0].high, equals(210.0));
        expect(result[0].low, equals(198.0));
        expect(result[0].close, equals(205.0));
        expect(result[0].volume, equals(2000000.0));
      });
    });

    group('Cache Hits', () {
      test('should return cached data without calling source', () async {
        // Arrange
        final symbol = 'AAPL';
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);
        final cachedPrices = [
          HistoricalPrice(
            date: DateTime(2025, 1, 1),
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 154.0,
            volume: 1000000.0,
          ),
        ];

        // Pre-populate cache
        await cache.save(
          symbol: symbol,
          start: start,
          end: end,
          prices: cachedPrices,
        );

        // Act
        final result = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Assert
        expect(result.length, equals(1));
        expect(result[0].close, equals(154.0));
        expect(fakeSource.fetchCallCount, equals(0)); // Source not called
      });

      test('should use cache for multiple requests with same parameters', () async {
        // Arrange
        final symbol = 'MSFT';
        final start = DateTime(2025, 3, 1);
        final end = DateTime(2025, 3, 15);
        final mockPrices = [
          HistoricalPrice(
            date: DateTime(2025, 3, 1),
            open: 300.0,
            high: 305.0,
            low: 298.0,
            close: 303.0,
            volume: 1500000.0,
          ),
        ];
        fakeSource.mockResponse = mockPrices;

        // Act - First request fetches from source
        final result1 = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Act - Second request should use cache
        final result2 = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Assert
        expect(result1.length, equals(result2.length));
        for (var i = 0; i < result1.length; i++) {
          final p1 = result1[i];
          final p2 = result2[i];
          expect(p1.date, equals(p2.date));
          expect(p1.open, equals(p2.open));
          expect(p1.high, equals(p2.high));
          expect(p1.low, equals(p2.low));
          expect(p1.close, equals(p2.close));
          expect(p1.volume, equals(p2.volume));
        }
        expect(fakeSource.fetchCallCount, equals(1)); // Called only once
      });

      test('should handle case-insensitive symbol caching', () async {
        // Arrange
        final start = DateTime(2025, 4, 1);
        final end = DateTime(2025, 4, 30);
        final mockPrices = [
          HistoricalPrice(
            date: DateTime(2025, 4, 1),
            open: 100.0,
            high: 102.0,
            low: 99.0,
            close: 101.0,
            volume: 500000.0,
          ),
        ];
        fakeSource.mockResponse = mockPrices;

        // Act - First request with lowercase
        await repository.getDailyPrices(
          symbol: 'aapl',
          start: start,
          end: end,
        );

        // Act - Second request with uppercase should hit cache
        final result = await repository.getDailyPrices(
          symbol: 'AAPL',
          start: start,
          end: end,
        );

        // Assert
        expect(result.length, equals(1));
        expect(fakeSource.fetchCallCount, equals(1)); // Called only once
      });
    });

    group('Cache Misses', () {
      test('should fetch from source when different symbol requested', () async {
        // Arrange
        final start = DateTime(2025, 5, 1);
        final end = DateTime(2025, 5, 31);
        final cachedPrices = [
          HistoricalPrice(
            date: DateTime(2025, 5, 1),
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 154.0,
            volume: 1000000.0,
          ),
        ];
        final newPrices = [
          HistoricalPrice(
            date: DateTime(2025, 5, 1),
            open: 200.0,
            high: 205.0,
            low: 199.0,
            close: 204.0,
            volume: 2000000.0,
          ),
        ];

        // Cache for AAPL
        await cache.save(
          symbol: 'AAPL',
          start: start,
          end: end,
          prices: cachedPrices,
        );

        fakeSource.mockResponse = newPrices;

        // Act - Request for different symbol TSLA
        final result = await repository.getDailyPrices(
          symbol: 'TSLA',
          start: start,
          end: end,
        );

        // Assert
        expect(result, equals(newPrices));
        expect(fakeSource.fetchCallCount, equals(1)); // Source called
      });

      test('should fetch from source when different date range requested', () async {
        // Arrange
        final symbol = 'AAPL';
        final cachedStart = DateTime(2025, 1, 1);
        final cachedEnd = DateTime(2025, 1, 31);
        final newStart = DateTime(2025, 2, 1);
        final newEnd = DateTime(2025, 2, 28);
        
        final cachedPrices = [
          HistoricalPrice(
            date: DateTime(2025, 1, 1),
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 154.0,
            volume: 1000000.0,
          ),
        ];
        final newPrices = [
          HistoricalPrice(
            date: DateTime(2025, 2, 1),
            open: 160.0,
            high: 165.0,
            low: 159.0,
            close: 164.0,
            volume: 1200000.0,
          ),
        ];

        // Cache for one date range
        await cache.save(
          symbol: symbol,
          start: cachedStart,
          end: cachedEnd,
          prices: cachedPrices,
        );

        fakeSource.mockResponse = newPrices;

        // Act - Request for different date range
        final result = await repository.getDailyPrices(
          symbol: symbol,
          start: newStart,
          end: newEnd,
        );

        // Assert
        expect(result, equals(newPrices));
        expect(fakeSource.fetchCallCount, equals(1)); // Source called
      });

      test('should save fetched data to cache after cache miss', () async {
        // Arrange
        final symbol = 'GOOG';
        final start = DateTime(2025, 6, 1);
        final end = DateTime(2025, 6, 30);
        final mockPrices = [
          HistoricalPrice(
            date: DateTime(2025, 6, 1),
            open: 2500.0,
            high: 2550.0,
            low: 2490.0,
            close: 2540.0,
            volume: 800000.0,
          ),
        ];
        fakeSource.mockResponse = mockPrices;

        // Act - First request (cache miss)
        await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Act - Second request (should be cache hit)
        final result = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Assert: compare field values rather than object identity
        expect(
          result
              .map((p) => [p.date, p.open, p.high, p.low, p.close, p.volume])
              .toList(),
          equals(
            mockPrices
                .map((p) => [p.date, p.open, p.high, p.low, p.close, p.volume])
                .toList(),
          ),
        );
        expect(fakeSource.fetchCallCount, equals(1)); // Only called once, second was cached
      });
    });

    group('Error Scenarios', () {
      test('should propagate errors from data source', () async {
        // Arrange
        final symbol = 'AAPL';
        final start = DateTime(2025, 7, 1);
        final end = DateTime(2025, 7, 31);
        fakeSource.mockError = Exception('API Error: Rate limit exceeded');

        // Act & Assert
        expect(
          () => repository.getDailyPrices(
            symbol: symbol,
            start: start,
            end: end,
          ),
          throwsException,
        );
      });

      test('should not cache when fetch fails', () async {
        // Arrange
        final symbol = 'AAPL';
        final start = DateTime(2025, 8, 1);
        final end = DateTime(2025, 8, 31);
        fakeSource.mockError = Exception('Network error');

        // Act - First request fails
        try {
          await repository.getDailyPrices(
            symbol: symbol,
            start: start,
            end: end,
          );
        } on Exception {
          // Expected to fail
        }

        // Arrange - Fix the error for second request
        fakeSource.mockError = null;
        final mockPrices = [
          HistoricalPrice(
            date: DateTime(2025, 8, 1),
            open: 170.0,
            high: 175.0,
            low: 169.0,
            close: 174.0,
            volume: 1300000.0,
          ),
        ];
        fakeSource.mockResponse = mockPrices;

        // Act - Second request should call source again (no cache from failed request)
        final result = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Assert
        expect(result, equals(mockPrices));
        expect(fakeSource.fetchCallCount, equals(2)); // Called twice due to first failure
      });

      test('should handle empty price list from source', () async {
        // Arrange
        final symbol = 'UNKNOWN';
        final start = DateTime(2025, 9, 1);
        final end = DateTime(2025, 9, 30);
        fakeSource.mockResponse = [];

        // Act
        final result = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Assert
        expect(result, isEmpty);
        expect(fakeSource.fetchCallCount, equals(1));
      });

      test('should cache empty price list from source', () async {
        // Arrange
        final symbol = 'EMPTY';
        final start = DateTime(2025, 10, 1);
        final end = DateTime(2025, 10, 31);
        fakeSource.mockResponse = [];

        // Act - First request
        await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Act - Second request should use cached empty list
        final result = await repository.getDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        );

        // Assert
        expect(result, isEmpty);
        expect(fakeSource.fetchCallCount, equals(1)); // Only called once
      });
    });
  });
}
