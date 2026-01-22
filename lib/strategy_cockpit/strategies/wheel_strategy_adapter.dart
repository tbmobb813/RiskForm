import 'trading_strategy.dart';
import 'leg.dart';
import 'payoff_point.dart';
import '../../models/option_contract.dart';
import '../../models/trade_inputs.dart';
import '../../services/engines/payoff_engine.dart';
import 'strategy_explanation.dart';

/// Adapter that represents a simplified Wheel cycle as a `TradingStrategy`.
///
/// This is intentionally conservative: it models a short put leg (cash-secured
/// put), an optional long share leg (assignment), and an optional short call
/// (covered call). It exposes legs and a deterministic intrinsic-based
/// `payoffCurve` so UI and analytics can consume a `TradingStrategy`.
class WheelStrategyAdapter extends TradingStrategy {
  @override
  final String id;
  @override
  final String label;

  final OptionContract putContract; // short put
  final OptionContract? callContract; // short call when shares owned
  final int shareQuantity;
  final double putPremiumReceived;
  final double callPremiumReceived;

  WheelStrategyAdapter({
    required this.id,
    required this.label,
    required this.putContract,
    this.callContract,
    this.shareQuantity = 100,
    double? putPremiumReceived,
    double? callPremiumReceived,
  })  : putPremiumReceived = putPremiumReceived ?? putContract.premium,
        callPremiumReceived = callPremiumReceived ?? (callContract?.premium ?? 0.0);

  @override
  List<Leg> get legs {
    final List<Leg> l = [];
    // short put
    l.add(Leg(contract: putContract, quantity: -1));
    // model assigned shares as long legs when present (adapter may include these)
    l.add(Leg(contract: OptionContract(id: 'SHARES', strike: 0.0, premium: 0.0, expiry: DateTime.now(), type: 'share'), quantity: shareQuantity));
    // short call if provided
    if (callContract != null) {
      l.add(Leg(contract: callContract!, quantity: -1));
    }
    return l;
  }

  @override
  double get maxRisk {
    // Conservative: max risk equals cost to buy shares minus put premium received
    final cost = putContract.strike * shareQuantity;
    return cost - (putPremiumReceived * shareQuantity);
  }

  @override
  double get maxProfit {
    // Capped when covered call present; otherwise limited to put premium
    if (callContract != null) {
      final cap = (callContract!.strike - putContract.strike) * shareQuantity;
      return cap - maxRisk;
    }
    return putPremiumReceived * shareQuantity;
  }

  @override
  double get breakeven {
    // When short put -> breakeven = put strike - put premium
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
        costBasis: putContract.strike, // assume entry at put strike
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

    // Fallback: model as CSP
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
    return StrategyExplanation(
      summary: 'Simplified Wheel adapter: sell put, accept assignment, sell covered call.',
      pros: ['Generates premium', 'Systematic income approach'],
      cons: ['Large capital requirement upon assignment', 'Assignment exposure'],
      idealConditions: ['Neutral to slightly bullish markets'],
      risks: ['Assignment and large capital lock-up', 'Opportunity cost when stock rallies'],
    );
  }
}
