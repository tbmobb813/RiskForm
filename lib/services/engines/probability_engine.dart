/// Pure-Dart probability estimates for short options and credit spreads.
///
/// Uses a lognormal model of the price at expiration. The probabilities are
/// risk-neutral and driven only by implied volatility, so they are estimates
/// for comparing trades, not forecasts.
library;

import 'dart:math' as math;

import 'position_sizing_engine.dart' show kContractMultiplier;

enum ProbabilitySide { shortPut, shortCall, putCreditSpread, callCreditSpread }

extension ProbabilitySideInfo on ProbabilitySide {
  bool get isPut =>
      this == ProbabilitySide.shortPut ||
      this == ProbabilitySide.putCreditSpread;
  bool get isSpread =>
      this == ProbabilitySide.putCreditSpread ||
      this == ProbabilitySide.callCreditSpread;
}

class ProbabilityInput {
  final ProbabilitySide side;
  final double spot;
  final double shortStrike;

  /// Spreads only: the protective strike (below the short strike for puts,
  /// above it for calls).
  final double? longStrike;

  /// Premium received per share (net credit for spreads).
  final double credit;
  final int dte;
  final double impliedVolPercent;
  final double riskFreeRatePercent;

  const ProbabilityInput({
    required this.side,
    required this.spot,
    required this.shortStrike,
    this.longStrike,
    required this.credit,
    required this.dte,
    required this.impliedVolPercent,
    this.riskFreeRatePercent = 4.0,
  });
}

class ProbabilityResult {
  /// Chance the short strike finishes in the money (assignment risk).
  final double probabilityInTheMoney;

  /// Chance the position finishes with a profit.
  final double probabilityOfProfit;

  /// Chance the full credit is kept.
  final double probabilityMaxProfit;

  final double breakeven;

  /// Distance from spot to the breakeven, as a percent of spot.
  final double breakevenDistancePercent;

  /// Distance from spot to the short strike, as a percent of spot.
  final double strikeDistancePercent;

  /// How many one-standard-deviation moves away the short strike is.
  final double strikeSigmaDistance;

  /// One standard deviation move in dollars over the period.
  final double expectedMove;
  final double lowerBound;
  final double upperBound;

  final double maxProfitPerContract;

  /// Null when the loss is unlimited (a call with no protective strike).
  final double? maxLossPerContract;
  final double? returnOnRiskPercent;

  const ProbabilityResult({
    required this.probabilityInTheMoney,
    required this.probabilityOfProfit,
    required this.probabilityMaxProfit,
    required this.breakeven,
    required this.breakevenDistancePercent,
    required this.strikeDistancePercent,
    required this.strikeSigmaDistance,
    required this.expectedMove,
    required this.lowerBound,
    required this.upperBound,
    required this.maxProfitPerContract,
    required this.maxLossPerContract,
    required this.returnOnRiskPercent,
  });
}

class ProbabilityEngine {
  const ProbabilityEngine();

  /// Standard normal cumulative distribution (Abramowitz and Stegun 7.1.26,
  /// absolute error under 1e-6).
  static double normalCdf(double x) {
    final sign = x < 0 ? -1.0 : 1.0;
    final z = x.abs() / math.sqrt2;
    final t = 1.0 / (1.0 + 0.3275911 * z);
    final poly =
        ((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t -
                0.284496736) *
            t +
        0.254829592;
    final erf = 1.0 - poly * t * math.exp(-z * z);
    return 0.5 * (1.0 + sign * erf);
  }

  /// Returns null when the inputs do not describe a valid position.
  ProbabilityResult? analyze(ProbabilityInput i) {
    if (!_isValid(i)) return null;

    final t = i.dte / 365;
    final sigma = i.impliedVolPercent / 100;
    final sigmaRootT = sigma * math.sqrt(t);
    final isPut = i.side.isPut;

    // P(price at expiration > k) under the lognormal model.
    double above(double k) {
      final d2 =
          (math.log(i.spot / k) +
              (i.riskFreeRatePercent / 100 - sigma * sigma / 2) * t) /
          sigmaRootT;
      return normalCdf(d2);
    }

    double beyond(double k) => isPut ? 1 - above(k) : above(k);

    final breakeven = isPut
        ? i.shortStrike - i.credit
        : i.shortStrike + i.credit;
    final inTheMoney = beyond(i.shortStrike);
    final profit = isPut ? above(breakeven) : 1 - above(breakeven);

    final width = i.side.isSpread
        ? (i.shortStrike - i.longStrike!).abs()
        : null;
    final maxLoss = switch (i.side) {
      ProbabilitySide.shortPut =>
        (i.shortStrike - i.credit) * kContractMultiplier,
      ProbabilitySide.shortCall => null,
      _ => (width! - i.credit) * kContractMultiplier,
    };
    final maxProfit = i.credit * kContractMultiplier;
    final expectedMove = i.spot * sigmaRootT;

    return ProbabilityResult(
      probabilityInTheMoney: inTheMoney,
      probabilityOfProfit: profit,
      probabilityMaxProfit: 1 - inTheMoney,
      breakeven: breakeven,
      breakevenDistancePercent: (breakeven - i.spot).abs() / i.spot * 100,
      strikeDistancePercent: (i.shortStrike - i.spot).abs() / i.spot * 100,
      strikeSigmaDistance: math.log(i.shortStrike / i.spot).abs() / sigmaRootT,
      expectedMove: expectedMove,
      lowerBound: i.spot - expectedMove,
      upperBound: i.spot + expectedMove,
      maxProfitPerContract: maxProfit,
      maxLossPerContract: maxLoss,
      returnOnRiskPercent: maxLoss == null || maxLoss <= 0
          ? null
          : maxProfit / maxLoss * 100,
    );
  }

  bool _isValid(ProbabilityInput i) {
    if (i.spot <= 0 || i.shortStrike <= 0) return false;
    if (i.dte <= 0 || i.impliedVolPercent <= 0 || i.credit < 0) return false;
    if (!i.riskFreeRatePercent.isFinite) return false;

    if (i.side.isSpread) {
      final long = i.longStrike;
      if (long == null || long <= 0) return false;
      final width = i.side.isPut ? i.shortStrike - long : long - i.shortStrike;
      if (width <= 0 || i.credit >= width) return false;
    }

    final breakeven = i.side.isPut
        ? i.shortStrike - i.credit
        : i.shortStrike + i.credit;
    return breakeven > 0;
  }
}
