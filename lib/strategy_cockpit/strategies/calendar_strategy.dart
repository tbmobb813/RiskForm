import 'trading_strategy.dart';
import 'strategy_explanation.dart';
import 'payoff_point.dart';
import 'leg.dart';
import '../../models/option_contract.dart';
import '../../models/trade_inputs.dart';
import '../../services/engines/payoff_engine.dart';

class CalendarStrategy extends TradingStrategy {
  final OptionContract longLeg;
  final OptionContract shortLeg;

  CalendarStrategy({required this.longLeg, required this.shortLeg});

  @override
  String get typeId => 'calendar';

  @override
  Map<String, dynamic> toJson() => {
        'longLeg': longLeg.toJson(),
        'shortLeg': shortLeg.toJson(),
      };

  @override
  String get id => 'calendar_${longLeg.id}_${shortLeg.id}';

  @override
  String get label => 'Calendar Spread';

  @override
  List<Leg> get legs => [Leg(contract: longLeg, quantity: 1), Leg(contract: shortLeg, quantity: -1)];

  @override
  double get maxRisk {
    // Approximate: cost of long premium minus short premium
    return (longLeg.premium - shortLeg.premium) * 100;
  }

  @override
  double get maxProfit => double.infinity; // can be large depending on movement

  @override
  double get breakeven => longLeg.strike + (longLeg.premium - shortLeg.premium);

  @override
  List<PayoffPoint> payoffCurve({required double underlyingPrice, required double rangePercent, required int steps}) {
    final engine = PayoffEngine();

    // Map to TradeInputs and use debit_spread as approximation for calendar payoff
    final inputs = TradeInputs(
      longStrike: longLeg.strike,
      shortStrike: shortLeg.strike,
      netDebit: (longLeg.premium - shortLeg.premium),
      underlyingPrice: underlyingPrice,
    );

    final minPrice = underlyingPrice * (1 - rangePercent);
    final maxPrice = underlyingPrice * (1 + rangePercent);

    final offsets = engine.generatePayoffCurve(
      strategyId: 'debit_spread',
      inputs: inputs,
      minPrice: minPrice,
      maxPrice: maxPrice,
      points: steps,
    );

    return offsets.map((o) => PayoffPoint(underlyingPrice: o.dx, profitLoss: o.dy)).toList();
  }

  @override
  StrategyExplanation explain() {
    return StrategyExplanation(
      summary: 'Calendar spread: long longer-dated option, short near-dated option at same strike.',
      pros: ['Time decay advantage on short leg', 'Can benefit from stable prices'],
      cons: ['Complex theta dynamics', 'Requires managing expiries'],
      idealConditions: ['Low-to-stable IV', 'Neutral market'],
      risks: ['Volatility shifts', 'Assignment risk on short leg near expiry'],
    );
  }
}
