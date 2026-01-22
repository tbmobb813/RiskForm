import 'trading_strategy.dart';
import 'strategy_explanation.dart';
import 'leg.dart';
import 'payoff_point.dart';
import '../../models/option_contract.dart';
import '../../models/trade_inputs.dart';
import '../../services/engines/payoff_engine.dart';

class LongPutStrategy extends TradingStrategy {
  final OptionContract contract;

  LongPutStrategy(this.contract);

  @override
  String get id => 'long_put_${contract.id}';

  @override
  String get label => 'Long Put';

  @override
  List<Leg> get legs => [Leg(contract: contract, quantity: 1)];

  @override
  double get maxRisk => contract.premium;

  @override
  double get maxProfit => contract.strike - contract.premium; // approx

  @override
  double get breakeven => contract.strike - contract.premium;

  @override
  List<PayoffPoint> payoffCurve({required double underlyingPrice, required double rangePercent, required int steps}) {
    final engine = PayoffEngine();

    final inputs = TradeInputs(
      strike: contract.strike,
      premiumPaid: contract.premium,
      underlyingPrice: underlyingPrice,
    );

    final minPrice = underlyingPrice * (1 - rangePercent);
    final maxPrice = underlyingPrice * (1 + rangePercent);

    final offsets = engine.generatePayoffCurve(
      strategyId: 'long_put',
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
      summary: 'A bearish strategy with defined risk and substantial downside protection.',
      pros: ['Defined risk', 'Downside protection'],
      cons: ['Time decay', 'Limited upside (premium)'],
      idealConditions: ['Bearish markets', 'High IV environments'],
      risks: ['Theta decay', 'IV crush'],
    );
  }
}
