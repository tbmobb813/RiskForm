import 'trading_strategy.dart';
import 'strategy_explanation.dart';
import 'leg.dart';
import 'payoff_point.dart';
import '../../models/option_contract.dart';
import '../../models/trade_inputs.dart';
import '../../services/engines/payoff_engine.dart';

class DebitSpreadStrategy extends TradingStrategy {
  final OptionContract longLeg;
  final OptionContract shortLeg;

  DebitSpreadStrategy({required this.longLeg, required this.shortLeg});

  @override
  String get id => 'debit_spread_${longLeg.id}_${shortLeg.id}';

  @override
  String get label => 'Debit Spread';

  @override
  List<Leg> get legs => [
        Leg(contract: longLeg, quantity: 1),
        Leg(contract: shortLeg, quantity: -1),
      ];

  @override
  double get maxRisk => (longLeg.premium - shortLeg.premium).abs();

  @override
  double get maxProfit => (shortLeg.strike - longLeg.strike) - maxRisk;

  @override
  double get breakeven => longLeg.strike + maxRisk;

  @override
  List<PayoffPoint> payoffCurve({required double underlyingPrice, required double rangePercent, required int steps}) {
    // Use PayoffEngine to produce a deterministic payoff curve

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
      summary: 'A defined-risk bullish strategy using two call options.',
      pros: ['Lower cost than long call', 'Defined risk', 'Reduced theta'],
      cons: ['Capped upside', 'Requires correct strike selection'],
      idealConditions: ['Moderately bullish trend', 'Moderate IV'],
      risks: ['Assignment risk on short leg', 'IV crush'],
    );
  }
}
