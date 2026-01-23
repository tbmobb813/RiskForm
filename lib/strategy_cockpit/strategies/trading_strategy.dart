import 'leg.dart';
import 'payoff_point.dart';
import 'strategy_explanation.dart';

/// Base trading strategy interface. Concrete strategies (Wheel, LongCall,
/// DebitSpread, etc.) should implement this API so planner and execution
/// code can treat them uniformly.
abstract class TradingStrategy {
  String get id;
  String get label;
  List<Leg> get legs;

  /// A stable type identifier for persistence (e.g. "long_call", "debit_spread", "wheel").
  String get typeId;

  /// JSON representation used for persistence. Implementation should produce
  /// only basic Dart types (maps, lists, strings, numbers, bools).
  Map<String, dynamic> toJson();

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
