import 'leg.dart';
import 'payoff_point.dart';
import 'strategy_explanation.dart';

abstract class TradingStrategy {
  String get id;
  String get label;
  List<Leg> get legs;

  double get maxRisk;
  double get maxProfit;
  double get breakeven;

  List<PayoffPoint> payoffCurve({
    required double underlyingPrice,
    required double rangePercent,
    required int steps,
  });

  StrategyExplanation explain();
}
