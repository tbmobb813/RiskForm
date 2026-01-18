import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/analytics/regime_classifier.dart';
import 'package:flutter_application_2/models/historical/historical_price.dart';
import 'package:flutter_application_2/models/analytics/market_regime.dart';

void main() {
  group('RegimeClassifier', () {
    late RegimeClassifier classifier;

    setUp(() {
      classifier = RegimeClassifier(
        lookbackDays: 10,
        upThreshold: 0.03,
        downThreshold: -0.03,
      );
    });

    group('Uptrend identification', () {
      test('identifies uptrend when return exceeds upThreshold', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 20,
          dailyReturn: 0.004, // ~4.1% over 10 days (compound return)
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.uptrend);
      });

      test('identifies uptrend at exact threshold', () {
        // Create prices where lookback return is exactly 3%
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        for (int i = 0; i < 15; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0,
            high: 100.0,
            low: 100.0,
            close: i < 10 ? 100.0 : 103.0, // 3% increase starting at day 10
            volume: 1000000,
          ));
        }

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.uptrend);
      });

      test('identifies sustained uptrend', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 30,
          dailyReturn: 0.005, // ~5.1% over 10 days (compound return)
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.every((s) => s.regime == MarketRegime.uptrend), true);
      });
    });

    group('Downtrend identification', () {
      test('identifies downtrend when return falls below downThreshold', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 20,
          dailyReturn: -0.004, // ~-3.9% over 10 days (compound return)
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.downtrend);
      });

      test('identifies downtrend at exact threshold', () {
        // Create prices where lookback return is exactly -3%
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        for (int i = 0; i < 15; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0,
            high: 100.0,
            low: 100.0,
            close: i < 10 ? 100.0 : 97.0, // -3% decrease after day 10
            volume: 1000000,
          ));
        }

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.downtrend);
      });

      test('identifies sustained downtrend', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 30,
          dailyReturn: -0.005, // ~-4.9% over 10 days (compound return)
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.every((s) => s.regime == MarketRegime.downtrend), true);
      });
    });

    group('Sideways market identification', () {
      test('identifies sideways when return is between thresholds', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 20,
          dailyReturn: 0.001, // 1% over 10 days - below threshold
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.sideways);
      });

      test('identifies sideways for flat market', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 20,
          dailyReturn: 0.0, // No change
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.sideways);
      });

      test('identifies sideways for small negative returns', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 20,
          dailyReturn: -0.001, // -1% over 10 days - above down threshold
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.sideways);
      });

      test('identifies sideways just below uptrend threshold', () {
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        for (int i = 0; i < 15; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0,
            high: 100.0,
            low: 100.0,
            close: i < 10 ? 100.0 : 102.9, // 2.9% increase - just below 3%
            volume: 1000000,
          ));
        }

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.sideways);
      });

      test('identifies sideways just above downtrend threshold', () {
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        for (int i = 0; i < 15; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0,
            high: 100.0,
            low: 100.0,
            close: i < 10 ? 100.0 : 97.1, // -2.9% decrease - just above -3%
            volume: 1000000,
          ));
        }

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.sideways);
      });
    });

    group('Regime transitions', () {
      test('correctly transitions from uptrend to downtrend', () {
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        // First 15 days: uptrend (price goes from 100 to 105)
        for (int i = 0; i < 15; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0 + (i * 0.5),
            high: 100.0 + (i * 0.5),
            low: 100.0 + (i * 0.5),
            close: 100.0 + (i * 0.5),
            volume: 1000000,
          ));
        }
        
        // Next 15 days: downtrend (price goes from 105 to 95)
        for (int i = 15; i < 30; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 105.0 - ((i - 15) * 0.67),
            high: 105.0 - ((i - 15) * 0.67),
            low: 105.0 - ((i - 15) * 0.67),
            close: 105.0 - ((i - 15) * 0.67),
            volume: 1000000,
          ));
        }

        final segments = classifier.classify(prices);

        expect(segments.length, greaterThanOrEqualTo(2));
        expect(segments.any((s) => s.regime == MarketRegime.uptrend), true);
        expect(segments.any((s) => s.regime == MarketRegime.downtrend), true);
      });

      test('correctly transitions from downtrend to uptrend', () {
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        // First 15 days: downtrend
        for (int i = 0; i < 15; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0 - (i * 0.5),
            high: 100.0 - (i * 0.5),
            low: 100.0 - (i * 0.5),
            close: 100.0 - (i * 0.5),
            volume: 1000000,
          ));
        }
        
        // Next 15 days: uptrend
        for (int i = 15; i < 30; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 93.0 + ((i - 15) * 0.67),
            high: 93.0 + ((i - 15) * 0.67),
            low: 93.0 + ((i - 15) * 0.67),
            close: 93.0 + ((i - 15) * 0.67),
            volume: 1000000,
          ));
        }

        final segments = classifier.classify(prices);

        expect(segments.length, greaterThanOrEqualTo(2));
        expect(segments.any((s) => s.regime == MarketRegime.downtrend), true);
        expect(segments.any((s) => s.regime == MarketRegime.uptrend), true);
      });

      test('segments have correct date ranges and indices', () {
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        // Uptrend for 15 days
        for (int i = 0; i < 15; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0 + (i * 0.5),
            high: 100.0 + (i * 0.5),
            low: 100.0 + (i * 0.5),
            close: 100.0 + (i * 0.5),
            volume: 1000000,
          ));
        }
        
        // Sideways for 15 days
        for (int i = 15; i < 30; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 107.0,
            high: 107.0,
            low: 107.0,
            close: 107.0,
            volume: 1000000,
          ));
        }

        final segments = classifier.classify(prices);

        for (final segment in segments) {
          // Verify date ranges are valid
          expect(segment.endDate.isAfter(segment.startDate) || 
                 segment.endDate.isAtSameMomentAs(segment.startDate), true);
          
          // Verify indices are valid
          expect(segment.endIndex, greaterThanOrEqualTo(segment.startIndex));
          expect(segment.startIndex, greaterThanOrEqualTo(0));
          expect(segment.endIndex, lessThan(prices.length));
        }
      });
    });

    group('Edge cases', () {
      test('returns empty list for insufficient data (less than lookbackDays + 1)', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 10, // Exactly lookbackDays, need lookbackDays + 1
          dailyReturn: 0.005,
        );

        final segments = classifier.classify(prices);

        expect(segments.isEmpty, true);
      });

      test('returns empty list for empty price list', () {
        final segments = classifier.classify([]);

        expect(segments.isEmpty, true);
      });

      test('handles minimum required data (lookbackDays + 1)', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 11, // lookbackDays + 1
          dailyReturn: 0.005,
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.length, 1);
      });

      test('handles custom lookback period', () {
        final customClassifier = RegimeClassifier(
          lookbackDays: 5,
          upThreshold: 0.03,
          downThreshold: -0.03,
        );

        final prices = _generatePrices(
          startPrice: 100.0,
          count: 10,
          dailyReturn: 0.01, // ~5.1% over 5 days (compound return)
        );

        final segments = customClassifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.uptrend);
      });

      test('handles custom thresholds', () {
        final customClassifier = RegimeClassifier(
          lookbackDays: 10,
          upThreshold: 0.05, // 5% threshold
          downThreshold: -0.05,
        );

        // 3% return should be sideways with these thresholds
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        for (int i = 0; i < 15; i++) {
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: 100.0,
            high: 100.0,
            low: 100.0,
            close: i < 10 ? 100.0 : 103.0, // 3% increase
            volume: 1000000,
          ));
        }

        final segments = customClassifier.classify(prices);

        expect(segments.isNotEmpty, true);
        expect(segments.first.regime, MarketRegime.sideways);
      });

      test('handles very large price lists', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 1000,
          dailyReturn: 0.002,
        );

        final segments = classifier.classify(prices);

        expect(segments.isNotEmpty, true);
        // Verify all segments are contiguous
        for (int i = 0; i < segments.length - 1; i++) {
          expect(segments[i].endIndex + 1, segments[i + 1].startIndex);
        }
      });

      test('handles price oscillations creating multiple segments', () {
        final prices = <HistoricalPrice>[];
        final baseDate = DateTime(2024, 1, 1);
        
        for (int i = 0; i < 50; i++) {
          // Alternate between up and down every 10 days
          final phase = (i ~/ 10) % 2;
          final priceInPhase = i % 10;
          final basePrice = 100.0;
          
          final price = phase == 0
              ? basePrice + (priceInPhase * 0.5) // Uptrend
              : basePrice - (priceInPhase * 0.5); // Downtrend
          
          prices.add(HistoricalPrice(
            date: baseDate.add(Duration(days: i)),
            open: price,
            high: price,
            low: price,
            close: price,
            volume: 1000000,
          ));
        }

        final segments = classifier.classify(prices);

        expect(segments.length, greaterThan(1));
      });
    });

    group('Segment continuity', () {
      test('segments cover entire price range without gaps', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 50,
          dailyReturn: 0.003,
        );

        final segments = classifier.classify(prices);

        // First segment should start at lookbackDays
        expect(segments.first.startIndex, 10);
        
        // Last segment should end at last price
        expect(segments.last.endIndex, prices.length - 1);
        
        // No gaps between segments
        for (int i = 0; i < segments.length - 1; i++) {
          expect(segments[i].endIndex + 1, segments[i + 1].startIndex);
        }
      });

      test('segment dates match price dates', () {
        final prices = _generatePrices(
          startPrice: 100.0,
          count: 30,
          dailyReturn: 0.004,
        );

        final segments = classifier.classify(prices);

        for (final segment in segments) {
          expect(prices[segment.startIndex].date, segment.startDate);
          expect(prices[segment.endIndex].date, segment.endDate);
        }
      });
    });
  });
}

/// Helper function to generate a list of prices with a constant daily return
List<HistoricalPrice> _generatePrices({
  required double startPrice,
  required int count,
  required double dailyReturn,
}) {
  final prices = <HistoricalPrice>[];
  final baseDate = DateTime(2024, 1, 1);
  
  for (int i = 0; i < count; i++) {
    final price = startPrice * math.pow(1 + dailyReturn, i);
    prices.add(HistoricalPrice(
      date: baseDate.add(Duration(days: i)),
      open: price,
      high: price,
      low: price,
      close: price,
      volume: 1000000,
    ));
  }
  
  return prices;
}
