import 'market_regime.dart';

class RegimeSegment {
  final MarketRegime regime;
  final DateTime startDate;
  final DateTime endDate;
  final int startIndex;
  final int endIndex;

  RegimeSegment({
    required this.regime,
    required this.startDate,
    required this.endDate,
    required this.startIndex,
    required this.endIndex,
  });
}
