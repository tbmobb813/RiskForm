import '../../models/analytics/regime_segment.dart';
import '../../models/historical/historical_price.dart';
import '../analytics/regime_classifier.dart';
import 'historical_repository.dart';

/// A symbol's historical prices paired with the regime windows classified
/// from them. `windows[i].startIndex`/`endIndex` index directly into
/// [prices], so callers can slice a specific window's closes without a
/// second fetch.
class RegimeCatalog {
  final List<HistoricalPrice> prices;
  final List<RegimeSegment> windows;

  RegimeCatalog({required this.prices, required this.windows});
}

/// Builds a browsable catalog of historical regime windows for a symbol by
/// combining [HistoricalRepository] (real price data) with [RegimeClassifier]
/// (existing regime segmentation), neither of which were previously wired
/// together.
class RegimeWindowCatalog {
  final HistoricalRepository repository;
  final RegimeClassifier classifier;

  RegimeWindowCatalog({required this.repository, RegimeClassifier? classifier})
    : classifier = classifier ?? RegimeClassifier();

  /// Fetches [symbol]'s daily prices between [start] and [end] and classifies
  /// them into regime windows, dropping windows shorter than
  /// [minDurationDays]. The classifier's 10-day-lookback/±3% threshold
  /// produces frequent short whipsaw segments; filtering keeps the result
  /// browsable and long enough to run a multi-cycle Wheel replay through.
  Future<RegimeCatalog> build({
    required String symbol,
    required DateTime start,
    required DateTime end,
    int minDurationDays = 15,
  }) async {
    final prices = await repository.getDailyPrices(
      symbol: symbol,
      start: start,
      end: end,
    );

    final windows = classifier
        .classify(prices)
        .where(
          (s) => s.endDate.difference(s.startDate).inDays >= minDurationDays,
        )
        .toList();

    return RegimeCatalog(prices: prices, windows: windows);
  }
}
