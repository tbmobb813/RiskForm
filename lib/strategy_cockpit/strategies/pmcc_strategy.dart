import 'trading_strategy.dart';
import 'strategy_explanation.dart';
import 'payoff_point.dart';
import 'leg.dart';
import '../../models/option_contract.dart';
import '../../models/trade_inputs.dart';
import '../../services/engines/payoff_engine.dart';

class PMCCStrategy extends TradingStrategy {
  final OptionContract callContract; // short call
  final int shareQuantity;
  final double costBasis;

  PMCCStrategy({required this.callContract, this.shareQuantity = 100, this.costBasis = 0.0});

  @override
  String get id => 'pmcc_${callContract.id}';

  @override
  String get label => 'PMCC (adapter)';

  @override
  List<Leg> get legs => [Leg(contract: OptionContract(id: 'SHARES', strike: 0.0, premium: 0.0, expiry: DateTime.now(), type: 'share'), quantity: shareQuantity), Leg(contract: callContract, quantity: -1)];

  @override
  double get maxRisk {
    // approximate: cost basis - call premium
    return (costBasis - callContract.premium) * shareQuantity;
  }

  @override
  double get maxProfit {
    return (callContract.strike - costBasis) * shareQuantity;
  }

  @override
  double get breakeven => costBasis - callContract.premium;

  @override
  List<PayoffPoint> payoffCurve({required double underlyingPrice, required double rangePercent, required int steps}) {
    final engine = PayoffEngine();

    // Map to covered call inputs
    final inputs = TradeInputs(
      strike: callContract.strike,
      premiumReceived: callContract.premium,
      costBasis: costBasis,
      underlyingPrice: underlyingPrice,
      sharesOwned: shareQuantity,
    );

    final minPrice = underlyingPrice * (1 - rangePercent);
    final maxPrice = underlyingPrice * (1 + rangePercent);

    final offsets = engine.generatePayoffCurve(
      strategyId: 'cc',
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
      summary: 'Poor Man\'s Covered Call: long synthetic or financed long plus short call.',
      pros: ['Lower capital requirement than owning 100 shares', 'Generates premium'],
      cons: ['Synthetic financing cost', 'Assignment exposure'],
      idealConditions: ['Mildly bullish to neutral markets'],
      risks: ['Volatility changes', 'Execution complexity'],
    );
  }
}
