import 'trading_strategy.dart';
import 'leg.dart';
import 'payoff_point.dart';
import '../../models/option_contract.dart';
import '../../models/trade_inputs.dart';
import '../../models/wheel_cycle.dart';
import '../../services/engines/payoff_engine.dart';
import 'strategy_explanation.dart';

/// First-class Wheel strategy implementing `TradingStrategy`.
///
/// This mirrors the behavior of the previous adapter but is a concrete
/// strategy type that can optionally hold a `WheelCycle` lifecycle object.
class WheelStrategy extends TradingStrategy {
  @override
  final String id;
  @override
  final String label;

  final OptionContract putContract;
  final OptionContract? callContract;
  final int shareQuantity;
  final double putPremiumReceived;
  final double callPremiumReceived;
  final WheelCycle? cycle;

  WheelStrategy({
    required this.id,
    required this.label,
    required this.putContract,
    this.callContract,
    this.shareQuantity = 100,
    double? putPremiumReceived,
    double? callPremiumReceived,
    this.cycle,
  })  : putPremiumReceived = putPremiumReceived ?? putContract.premium,
        callPremiumReceived = callPremiumReceived ?? (callContract?.premium ?? 0.0);

  @override
  List<Leg> get legs {
    final List<Leg> l = [];
    // short put
    l.add(Leg(contract: putContract, quantity: -1));

    // model assigned shares as long legs when present
    l.add(Leg(contract: OptionContract(id: 'SHARES', strike: 0.0, premium: 0.0, expiry: DateTime.now(), type: 'share'), quantity: shareQuantity));

    // short call if provided
    if (callContract != null) {
      l.add(Leg(contract: callContract!, quantity: -1));
    }

    return l;
  }

  @override
  double get maxRisk {
    final cost = putContract.strike * shareQuantity;
    return cost - (putPremiumReceived * shareQuantity);
  }

  @override
  double get maxProfit {
    if (callContract != null) {
      final cap = (callContract!.strike - putContract.strike) * shareQuantity;
      return cap - maxRisk;
    }
    return putPremiumReceived * shareQuantity;
  }

  @override
  double get breakeven {
    return putContract.strike - putPremiumReceived;
  }

  @override
  List<PayoffPoint> payoffCurve({required double underlyingPrice, required double rangePercent, required int steps}) {
    final engine = PayoffEngine();

    // If we have shares + call, model as covered call; otherwise model as CSP
    if (callContract != null && shareQuantity >= 100) {
      final inputs = TradeInputs(
        strike: callContract!.strike,
        premiumReceived: callPremiumReceived,
        costBasis: putContract.strike,
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

    final inputs = TradeInputs(
      strike: putContract.strike,
      premiumReceived: putPremiumReceived,
      underlyingPrice: underlyingPrice,
    );

    final minPrice = underlyingPrice * (1 - rangePercent);
    final maxPrice = underlyingPrice * (1 + rangePercent);

    final offsets = engine.generatePayoffCurve(
      strategyId: 'csp',
      inputs: inputs,
      minPrice: minPrice,
      maxPrice: maxPrice,
      points: steps,
    );

    return offsets.map((o) => PayoffPoint(underlyingPrice: o.dx, profitLoss: o.dy)).toList();
  }

  @override
  StrategyExplanation explain() {
    final base = StrategyExplanation(
      summary: 'Wheel strategy: sell put, accept assignment, sell covered call.',
      pros: ['Generates premium', 'Systematic income approach'],
      cons: ['Large capital requirement upon assignment', 'Assignment exposure'],
      idealConditions: ['Neutral to slightly bullish markets'],
      risks: ['Assignment and large capital lock-up', 'Opportunity cost when stock rallies'],
    );

    if (cycle == null) return base;

    // Add a short note about current cycle state
    return StrategyExplanation(
      summary: '${base.summary} Current cycle state: ${cycle!.state}.',
      pros: base.pros,
      cons: base.cons,
      idealConditions: base.idealConditions,
      risks: base.risks,
    );
  }
}
