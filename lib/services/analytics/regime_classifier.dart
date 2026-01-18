import '../../models/historical/historical_price.dart';
import '../../models/analytics/regime_segment.dart';
import '../../models/analytics/market_regime.dart';

class RegimeClassifier {
  final int lookbackDays;
  final double upThreshold;
  final double downThreshold;

  RegimeClassifier({
    this.lookbackDays = 10,
    this.upThreshold = 0.03,
    this.downThreshold = -0.03,
  });

  List<RegimeSegment> classify(List<HistoricalPrice> prices) {
    if (prices.length < lookbackDays + 1) return [];

    final segments = <RegimeSegment>[];

    MarketRegime? currentRegime;
    DateTime? segmentStart;
    int startIndex = 0;

    for (int i = lookbackDays; i < prices.length; i++) {
      final past = prices[i - lookbackDays].close;
      final now = prices[i].close;
      final ret = (now - past) / past;

      final regime = _regimeForReturn(ret);

      if (currentRegime == null) {
        currentRegime = regime;
        segmentStart = prices[i].date;
        startIndex = i;
      } else if (regime != currentRegime) {
        segments.add(RegimeSegment(
          regime: currentRegime,
          startDate: segmentStart!,
          endDate: prices[i - 1].date,
          startIndex: startIndex,
          endIndex: i - 1,
        ));
        currentRegime = regime;
        segmentStart = prices[i].date;
        startIndex = i;
      }
    }

    if (currentRegime != null && segmentStart != null) {
      segments.add(RegimeSegment(
        regime: currentRegime,
        startDate: segmentStart,
        endDate: prices.last.date,
        startIndex: startIndex,
        endIndex: prices.length - 1,
      ));
    }

    return segments;
  }

  MarketRegime _regimeForReturn(double r) {
    if (r >= upThreshold) return MarketRegime.uptrend;
    if (r <= downThreshold) return MarketRegime.downtrend;
    return MarketRegime.sideways;
  }
}
