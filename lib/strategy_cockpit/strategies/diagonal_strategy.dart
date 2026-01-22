import 'trading_strategy.dart';
import 'strategy_explanation.dart';
import 'payoff_point.dart';
import 'leg.dart';
import '../../models/option_contract.dart';
import '../../models/trade_inputs.dart';
import '../../services/engines/payoff_engine.dart';

class DiagonalStrategy extends TradingStrategy {
  final OptionContract longLeg;
  final OptionContract shortLeg;

  DiagonalStrategy({required this.longLeg, required this.shortLeg});

  @override
  String get typeId => 'diagonal';

  @override
  Map<String, dynamic> toJson() => {
        'longLeg': longLeg.toJson(),
        'shortLeg': shortLeg.toJson(),
      };

  @override
  String get id => 'diagonal_${longLeg.id}_${shortLeg.id}';

  @override
  String get label => 'Diagonal Spread';

  @override
  List<Leg> get legs => [Leg(contract: longLeg, quantity: 1), Leg(contract: shortLeg, quantity: -1)];

  @override
  double get maxRisk {
    return (longLeg.premium - shortLeg.premium) * 100;
  }

  @override
  double get maxProfit => double.infinity;

  @override
  double get breakeven => longLeg.strike + (longLeg.premium - shortLeg.premium);

  @override
  List<PayoffPoint> payoffCurve({required double underlyingPrice, required double rangePercent, required int steps}) {
    final engine = PayoffEngine();

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
      summary: 'Diagonal spread: long option with longer expiry and short option near-dated at different strike.',
      pros: ['Flexibility of strike + time', 'Potential time decay advantage'],
      cons: ['Complex Greeks interaction', 'Requires monitoring of expiries and assignment risk'],
      idealConditions: ['Neutral to slightly directional thesis', 'Moderate IV environment'],
      risks: ['Volatility shifts', 'Assignment on short leg'],
    );
  }
}
