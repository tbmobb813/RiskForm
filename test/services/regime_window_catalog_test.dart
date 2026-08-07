import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/historical/historical_price.dart';
import 'package:riskform/services/historical/historical_cache.dart';
import 'package:riskform/services/historical/historical_repository.dart';
import 'package:riskform/services/historical/regime_window_catalog.dart';

import '../fakes/fake_box.dart';
import '../fakes/fake_historical_data_source.dart';

List<HistoricalPrice> _pricesFor(List<double> closes) {
  final baseDate = DateTime(2024, 1, 1);
  return [
    for (int i = 0; i < closes.length; i++)
      HistoricalPrice(
        date: baseDate.add(Duration(days: i)),
        open: closes[i],
        high: closes[i],
        low: closes[i],
        close: closes[i],
        volume: 1000000,
      ),
  ];
}

void main() {
  group('RegimeWindowCatalog', () {
    late FakeHistoricalDataSource source;
    late HistoricalRepository repository;
    late RegimeWindowCatalog catalog;

    setUp(() {
      source = FakeHistoricalDataSource();
      repository = HistoricalRepository(
        source: source,
        cache: HistoricalCache(FakeBox()),
      );
      catalog = RegimeWindowCatalog(repository: repository);
    });

    test('classifies fetched prices into windows', () async {
      // 15 flat days, then a sustained uptrend for 20 days.
      final closes = [
        for (int i = 0; i < 15; i++) 100.0,
        for (int i = 0; i < 20; i++) 100.0 * (1 + 0.006 * i),
      ];
      source.mockResponse = _pricesFor(closes);

      final result = await catalog.build(
        symbol: 'SPY',
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 3, 1),
        minDurationDays: 0,
      );

      expect(result.prices.length, closes.length);
      expect(result.windows, isNotEmpty);
      expect(source.fetchCallCount, 1);

      // Index ranges must line up with the fetched price list.
      for (final segment in result.windows) {
        expect(result.prices[segment.startIndex].date, segment.startDate);
        expect(result.prices[segment.endIndex].date, segment.endDate);
      }
    });

    test('filters out windows shorter than minDurationDays', () async {
      // Rapid alternation creates several short segments.
      final closes = [
        for (int i = 0; i < 60; i++)
          100.0 + (i % 10 < 5 ? (i % 10) * 0.8 : -(i % 10) * 0.8),
      ];
      source.mockResponse = _pricesFor(closes);

      final unfiltered = await catalog.build(
        symbol: 'SPY',
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 3, 1),
        minDurationDays: 0,
      );
      final filtered = await catalog.build(
        symbol: 'SPY',
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 3, 1),
        minDurationDays: 15,
      );

      expect(
        filtered.windows.length,
        lessThanOrEqualTo(unfiltered.windows.length),
      );
      for (final segment in filtered.windows) {
        expect(
          segment.endDate.difference(segment.startDate).inDays,
          greaterThanOrEqualTo(15),
        );
      }
    });

    test('returns empty windows for insufficient data', () async {
      source.mockResponse = _pricesFor([100.0, 101.0, 102.0]);

      final result = await catalog.build(
        symbol: 'SPY',
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 3),
      );

      expect(result.windows, isEmpty);
    });
  });
}
