import 'dart:math';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trade_inputs.dart';
import '../../models/payoff_result.dart';
import '../../models/option_contract.dart';

final payoffEngineProvider = Provider<PayoffEngine>((ref) {
  return PayoffEngine();
});

class PayoffEngine {
  static const int contractSize = 100;

  Future<PayoffResult> compute({
    required String strategyId,
    required TradeInputs inputs,
  }) async {
    switch (strategyId) {
      case "csp":
        return _cashSecuredPut(inputs);
      case "cc":
        return _coveredCall(inputs);
      case "credit_spread":
        return _creditSpread(inputs);
      case "debit_spread":
        return _debitSpread(inputs);
      case "long_call":
        return _longCall(inputs);
      case "long_put":
        return _longPut(inputs);
      case "protective_put":
        return _protectivePut(inputs);
      case "collar":
        return _collar(inputs);
      default:
        return _placeholder(inputs);
    }
  }

  // --- STRATEGIES ---

  // Cash-Secured Put
  // Short put, fully collateralized with cash.
  PayoffResult _cashSecuredPut(TradeInputs i) {
    final K = i.strike ?? 0;
    final premium = i.premiumReceived ?? 0;

    final capitalRequired = K * contractSize;
    final maxGain = premium * contractSize;
    final maxLoss = (K - premium) * contractSize; // if underlying → 0
    final breakeven = K - premium;

    return PayoffResult(
      maxGain: maxGain,
      maxLoss: maxLoss,
      breakeven: breakeven,
      capitalRequired: capitalRequired,
    );
  }

  // Covered Call
  // Long 100 shares, short 1 call.
  PayoffResult _coveredCall(TradeInputs i) {
    final K = i.strike ?? 0;
    final premium = i.premiumReceived ?? 0;
    final costBasis = i.costBasis ?? 0;

    final capitalRequired = costBasis * contractSize;

    final maxGainPerShare = (K - costBasis) + premium;
    final maxGain = maxGainPerShare * contractSize;

    final maxLossPerShare = costBasis - premium; // if underlying → 0
    final maxLoss = maxLossPerShare * contractSize;

    final breakeven = costBasis - premium;

    return PayoffResult(
      maxGain: maxGain,
      maxLoss: maxLoss,
      breakeven: breakeven,
      capitalRequired: capitalRequired,
    );
  }

  // Credit Spread (put credit spread)
  // Short higher strike put, long lower strike put.
  PayoffResult _creditSpread(TradeInputs i) {
    final kShort = i.shortStrike ?? 0;
    final kLong = i.longStrike ?? 0;
    final credit = i.netCredit ?? 0;

    final width = (kShort - kLong).abs();
    final maxGain = credit * contractSize;
    final maxLoss = (width - credit) * contractSize;
    final breakeven = kShort - credit;
    final capitalRequired = maxLoss; // defined-risk

    return PayoffResult(
      maxGain: maxGain,
      maxLoss: maxLoss,
      breakeven: breakeven,
      capitalRequired: capitalRequired,
    );
  }

  // Debit Spread (call debit spread)
  // Long lower strike call, short higher strike call.
  PayoffResult _debitSpread(TradeInputs i) {
    final kLong = i.longStrike ?? 0;
    final kShort = i.shortStrike ?? 0;
    final debit = i.netDebit ?? 0;

    final width = (kShort - kLong).abs();
    final maxGain = (width - debit) * contractSize;
    final maxLoss = debit * contractSize;
    final breakeven = kLong + debit;
    final capitalRequired = maxLoss;

    return PayoffResult(
      maxGain: maxGain,
      maxLoss: maxLoss,
      breakeven: breakeven,
      capitalRequired: capitalRequired,
    );
  }

  // Long Call
  PayoffResult _longCall(TradeInputs i) {
    final K = i.strike ?? 0;
    final premium = i.premiumPaid ?? 0;

    final maxGain = double.infinity; // conceptually
    final maxLoss = premium * contractSize;
    final breakeven = K + premium;
    final capitalRequired = maxLoss;

    return PayoffResult(
      maxGain: maxGain,
      maxLoss: maxLoss,
      breakeven: breakeven,
      capitalRequired: capitalRequired,
    );
  }

  // Long Put
  PayoffResult _longPut(TradeInputs i) {
    final K = i.strike ?? 0;
    final premium = i.premiumPaid ?? 0;

    final maxGain = (K - premium) * contractSize; // if underlying → 0
    final maxLoss = premium * contractSize;
    final breakeven = K - premium;
    final capitalRequired = maxLoss;

    return PayoffResult(
      maxGain: maxGain,
      maxLoss: maxLoss,
      breakeven: breakeven,
      capitalRequired: capitalRequired,
    );
  }

  // Protective Put
  // Long 100 shares + long put.
  PayoffResult _protectivePut(TradeInputs i) {
    final K = i.strike ?? 0;
    final premium = i.premiumPaid ?? 0;
    final costBasis = i.costBasis ?? 0;

    final capitalRequired = (costBasis + premium) * contractSize;

    final maxGain = double.infinity; // upside open
    final maxLossPerShare = (costBasis + premium) - K;
    final maxLoss = maxLossPerShare * contractSize;

    final breakeven = costBasis + premium;

    return PayoffResult(
      maxGain: maxGain,
      maxLoss: maxLoss,
      breakeven: breakeven,
      capitalRequired: capitalRequired,
    );
  }

  // Collar
  // Long 100 shares + long put + short call.
  PayoffResult _collar(TradeInputs i) {
    final kCall = i.strike ?? 0; // using strike as call strike
    final kPut = i.longStrike ?? 0;
    final callPremium = i.premiumReceived ?? 0;
    final putPremium = i.premiumPaid ?? 0;
    final costBasis = i.costBasis ?? 0;

    final netPremium = callPremium - putPremium;

    final capitalRequired = (costBasis + putPremium - callPremium) * contractSize;

    final maxGainPerShare = (kCall - costBasis) + netPremium;
    final maxGain = maxGainPerShare * contractSize;

    final maxLossPerShare = (costBasis + netPremium) - kPut;
    final maxLoss = maxLossPerShare * contractSize;

    final breakeven = costBasis + netPremium;

    return PayoffResult(
      maxGain: maxGain,
      maxLoss: maxLoss,
      breakeven: breakeven,
      capitalRequired: capitalRequired,
    );
  }

  // Fallback
  PayoffResult _placeholder(TradeInputs i) {
    final underlying = i.underlyingPrice ?? 0;
    return PayoffResult(
      maxGain: 0,
      maxLoss: 0,
      breakeven: underlying,
      capitalRequired: 0,
    );
  }

  // --- Payoff curve helpers ---

  /// Generate a deterministic payoff curve as a list of `Offset(price, profit)`
  /// Values are returned in dollars per contract (uses `contractSize`).
  List<Offset> generatePayoffCurve({
    required String strategyId,
    required TradeInputs inputs,
    required double minPrice,
    required double maxPrice,
    int points = 80,
  }) {
    final List<Offset> curve = [];

    final step = (maxPrice - minPrice) / (points - 1);

    for (int i = 0; i < points; i++) {
      final price = minPrice + (i * step);
      final payoff = payoffAtPrice(
        strategyId: strategyId,
        inputs: inputs,
        underlyingPrice: price,
      );
      curve.add(Offset(price, payoff));
    }

    return curve;
  }

  /// Compute payoff (in dollars per contract) at a single underlying price.
  double payoffAtPrice({
    required String strategyId,
    required TradeInputs inputs,
    required double underlyingPrice,
  }) {
    switch (strategyId) {
      case "csp":
        return _cspAtPrice(inputs, underlyingPrice);
      case "cc":
        return _ccAtPrice(inputs, underlyingPrice);
      case "credit_spread":
        return _creditSpreadAtPrice(inputs, underlyingPrice);
      case "debit_spread":
        return _debitSpreadAtPrice(inputs, underlyingPrice);
      case "long_call":
        return _longCallAtPrice(inputs, underlyingPrice);
      case "long_put":
        return _longPutAtPrice(inputs, underlyingPrice);
      case "protective_put":
        return _protectivePutAtPrice(inputs, underlyingPrice);
      case "collar":
        return _collarAtPrice(inputs, underlyingPrice);
      default:
        return 0;
    }
  }

  double _cspAtPrice(TradeInputs i, double S) {
    final K = i.strike ?? 0;
    final premium = i.premiumReceived ?? 0;
    final perShare = (S < K) ? (premium - (K - S)) : premium;
    return perShare * contractSize;
  }

  double _ccAtPrice(TradeInputs i, double S) {
    final K = i.strike ?? 0;
    final premium = i.premiumReceived ?? 0;
    final costBasis = i.costBasis ?? 0;

    final intrinsic = S - costBasis;
    final capped = S <= K ? intrinsic : (K - costBasis);
    final perShare = capped + premium;
    return perShare * contractSize;
  }

  double _creditSpreadAtPrice(TradeInputs i, double S) {
    final kShort = i.shortStrike ?? 0;
    final kLong = i.longStrike ?? 0;
    final credit = i.netCredit ?? 0;

    final perShare = credit - max(0, kShort - S) + max(0, kLong - S);
    return perShare * contractSize;
  }

  double _debitSpreadAtPrice(TradeInputs i, double S) {
    final kLong = i.longStrike ?? 0;
    final kShort = i.shortStrike ?? 0;
    final debit = i.netDebit ?? 0;

    final perShare = -debit + max(0, S - kLong) - max(0, S - kShort);
    return perShare * contractSize;
  }

  double _longCallAtPrice(TradeInputs i, double S) {
    final K = i.strike ?? 0;
    final premium = i.premiumPaid ?? 0;

    final perShare = -premium + max(0, S - K);
    return perShare * contractSize;
  }

  double _longPutAtPrice(TradeInputs i, double S) {
    final K = i.strike ?? 0;
    final premium = i.premiumPaid ?? 0;

    final perShare = -premium + max(0, K - S);
    return perShare * contractSize;
  }

  double _protectivePutAtPrice(TradeInputs i, double S) {
    final K = i.strike ?? 0;
    final premium = i.premiumPaid ?? 0;
    final costBasis = i.costBasis ?? 0;

    final perShare = (S - costBasis) - premium + max(0, K - S);
    return perShare * contractSize;
  }

  double _collarAtPrice(TradeInputs i, double S) {
    final kCall = i.strike ?? 0;
    final kPut = i.longStrike ?? 0;
    final callPremium = i.premiumReceived ?? 0;
    final putPremium = i.premiumPaid ?? 0;
    final costBasis = i.costBasis ?? 0;
    final perShare = (S - costBasis) + (callPremium - max(0, S - kCall)) + (-putPremium + max(0, kPut - S));
    return perShare * contractSize;
  }

  /// Compute payoff (in dollars per contract) for an explicit set of option/share
  /// contracts with matching quantities. `contracts` and `quantities` must have
  /// the same length. Quantity follows convention: +1 long, -1 short.
  double payoffForContractsWithQuantities({
    required List<OptionContract> contracts,
    required List<int> quantities,
    required double underlyingPrice,
  }) {
    if (contracts.length != quantities.length) {
      throw ArgumentError('contracts and quantities length mismatch');
    }

    double total = 0.0;

    for (int i = 0; i < contracts.length; i++) {
      final c = contracts[i];
      final q = quantities[i];

      if (c.type == 'call') {
        final intrinsic = max(0, underlyingPrice - c.strike);
        // Options are quoted per-contract; multiply by contractSize for dollar amount.
        total += q * (-c.premium + intrinsic) * contractSize;
      } else if (c.type == 'put') {
        final intrinsic = max(0, c.strike - underlyingPrice);
        total += q * (-c.premium + intrinsic) * contractSize;
      } else if (c.type == 'share') {
        // For share legs, `quantity` represents number of shares and `premium`
        // is used as cost-basis per share.
        total += q * (underlyingPrice - c.premium);
      } else {
        // Unknown contract type: ignore
      }
    }

    return total;
  }

  /// Generate payoff curve for explicit contract lists.
  List<Offset> generatePayoffCurveForContracts({
    required List<OptionContract> contracts,
    required List<int> quantities,
    required double minPrice,
    required double maxPrice,
    int points = 80,
  }) {
    final List<Offset> curve = [];
    final step = (maxPrice - minPrice) / (points - 1);

    for (int i = 0; i < points; i++) {
      final price = minPrice + (i * step);
      final payoff = payoffForContractsWithQuantities(
        contracts: contracts,
        quantities: quantities,
        underlyingPrice: price,
      );
      curve.add(Offset(price, payoff));
    }

    return curve;
  }
}