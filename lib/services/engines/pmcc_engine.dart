/// Pure-Dart analysis of a poor man's covered call: a deep in-the-money LEAPS
/// call with a nearer-dated short call sold against it.
///
/// Prices are per share. Profit figures are conservative: at the short call's
/// expiration the LEAPS is valued at intrinsic value only, so real results
/// should be at least as good when time value remains.
library;

import 'position_sizing_engine.dart' show kContractMultiplier;

/// Rule-of-thumb guidelines. They flag setups worth a second look and are not
/// hard limits.
class PmccGuidelines {
  PmccGuidelines._();

  static const double minLeapsDelta = 0.70;
  static const int minLeapsDte = 270;
  static const double maxExtrinsicPercent = 30;

  /// The width between strikes should exceed the net debit by at least this
  /// factor, or the best case is thin.
  static const double minWidthToDebit = 1.25;
}

class PmccInput {
  final double spot;

  final double leapsStrike;

  /// What you paid for the LEAPS, per share.
  final double leapsCost;
  final int leapsDte;

  /// LEAPS delta between 0 and 1, when known.
  final double? leapsDelta;

  final double shortStrike;

  /// Credit received for the current short call, per share.
  final double shortCredit;
  final int shortDte;

  /// Net premium from earlier short calls (after buybacks), per share.
  final double premiumsCollected;

  const PmccInput({
    required this.spot,
    required this.leapsStrike,
    required this.leapsCost,
    required this.leapsDte,
    this.leapsDelta,
    required this.shortStrike,
    required this.shortCredit,
    required this.shortDte,
    this.premiumsCollected = 0,
  });
}

class PmccResult {
  /// Strike plus cost: the stock price the LEAPS stands in for.
  final double syntheticStockCost;

  /// Net cash in the position after all short-call premium. Zero or negative
  /// means the cost has been fully recovered.
  final double netDebit;

  /// Stock price equivalent of your net cost. Also the conservative
  /// breakeven at the short call's expiration.
  final double effectiveBasis;

  final double intrinsicValue;
  final double extrinsicValue;
  final double extrinsicPercentOfCost;

  /// Distance between the strikes.
  final double width;

  /// Best case at the short expiration (stock at or above the short strike),
  /// including premiums already collected.
  final double maxProfitPerShare;
  final double maxProfitPerContract;

  /// Loss if the LEAPS expires worthless, never below zero.
  final double maxLossPerContract;

  /// What the LEAPS costs up front, per contract.
  final double leapsCapitalPerContract;

  /// What 100 shares would cost, per contract.
  final double sharesCapitalPerContract;
  final double capitalSavingsPercent;

  /// Best-case return of this short call cycle on the capital tied up, using
  /// only this cycle's credit.
  final double cycleReturnPercent;

  /// The same cycle's best-case return for an ordinary covered call on shares.
  final double sharesCycleReturnPercent;

  final bool shortInTheMoney;
  final double shortStrikeDistancePercent;

  final List<String> warnings;

  const PmccResult({
    required this.syntheticStockCost,
    required this.netDebit,
    required this.effectiveBasis,
    required this.intrinsicValue,
    required this.extrinsicValue,
    required this.extrinsicPercentOfCost,
    required this.width,
    required this.maxProfitPerShare,
    required this.maxProfitPerContract,
    required this.maxLossPerContract,
    required this.leapsCapitalPerContract,
    required this.sharesCapitalPerContract,
    required this.capitalSavingsPercent,
    required this.cycleReturnPercent,
    required this.sharesCycleReturnPercent,
    required this.shortInTheMoney,
    required this.shortStrikeDistancePercent,
    required this.warnings,
  });
}

class PmccEngine {
  const PmccEngine();

  /// Returns null when the inputs do not describe a valid structure.
  PmccResult? analyze(PmccInput i) {
    if (!_isValid(i)) return null;

    final intrinsic = i.spot > i.leapsStrike ? i.spot - i.leapsStrike : 0.0;
    final extrinsic = i.leapsCost - intrinsic;
    final extrinsicPercent = extrinsic / i.leapsCost * 100;

    final netDebit = i.leapsCost - i.shortCredit - i.premiumsCollected;
    final width = i.shortStrike - i.leapsStrike;
    final maxProfit = width - netDebit;

    final cycleDebit = i.leapsCost - i.shortCredit;
    final sharesNet = i.spot - i.shortCredit;

    final warnings = <String>[];
    final delta = i.leapsDelta;
    if (delta != null && delta < PmccGuidelines.minLeapsDelta) {
      warnings.add(
        'LEAPS delta ${delta.toStringAsFixed(2)} is below '
        '${PmccGuidelines.minLeapsDelta.toStringAsFixed(2)}, so it will '
        'track the stock less closely.',
      );
    }
    if (i.leapsDte < PmccGuidelines.minLeapsDte) {
      warnings.add(
        'LEAPS has ${i.leapsDte} days left, under about 9 months, so time '
        'value is decaying faster.',
      );
    }
    if (i.spot <= i.leapsStrike) {
      warnings.add(
        'LEAPS is not in the money, so it is not a stock substitute.',
      );
    } else if (extrinsicPercent > PmccGuidelines.maxExtrinsicPercent) {
      warnings.add(
        'Time value is ${extrinsicPercent.toStringAsFixed(0)}% of what you '
        'paid, more than the ${PmccGuidelines.maxExtrinsicPercent.toStringAsFixed(0)}% guideline.',
      );
    }
    if (width <= netDebit) {
      warnings.add(
        'If assigned at the short strike you lose money even in the best '
        'case: the strike gap (\$${width.toStringAsFixed(2)}) does not cover '
        'your net cost (\$${netDebit.toStringAsFixed(2)}).',
      );
    } else if (netDebit > 0 &&
        width < netDebit * PmccGuidelines.minWidthToDebit) {
      warnings.add(
        'The strike gap is thin relative to your net cost, leaving little '
        'room for profit if the short call is assigned.',
      );
    }
    if (i.spot > i.shortStrike) {
      warnings.add(
        'The short call is in the money. Consider rolling it before it is '
        'assigned.',
      );
    }

    return PmccResult(
      syntheticStockCost: i.leapsStrike + i.leapsCost,
      netDebit: netDebit,
      effectiveBasis: i.leapsStrike + netDebit,
      intrinsicValue: intrinsic,
      extrinsicValue: extrinsic,
      extrinsicPercentOfCost: extrinsicPercent,
      width: width,
      maxProfitPerShare: maxProfit,
      maxProfitPerContract: maxProfit * kContractMultiplier,
      maxLossPerContract: (netDebit > 0 ? netDebit : 0.0) * kContractMultiplier,
      leapsCapitalPerContract: i.leapsCost * kContractMultiplier,
      sharesCapitalPerContract: i.spot * kContractMultiplier,
      capitalSavingsPercent: (i.spot - i.leapsCost) / i.spot * 100,
      cycleReturnPercent: cycleDebit > 0
          ? (width - cycleDebit) / cycleDebit * 100
          : 0,
      sharesCycleReturnPercent:
          (i.shortStrike - i.spot + i.shortCredit) / sharesNet * 100,
      shortInTheMoney: i.spot > i.shortStrike,
      shortStrikeDistancePercent: (i.shortStrike - i.spot).abs() / i.spot * 100,
      warnings: warnings,
    );
  }

  bool _isValid(PmccInput i) {
    if (i.spot <= 0 || i.leapsStrike <= 0 || i.shortStrike <= 0) return false;
    if (i.leapsCost <= 0 || i.shortCredit < 0 || i.premiumsCollected < 0) {
      return false;
    }
    if (i.leapsDte <= 0 || i.shortDte <= 0) return false;
    // The short call must expire before the LEAPS, above its strike.
    if (i.shortDte >= i.leapsDte) return false;
    if (i.shortStrike <= i.leapsStrike) return false;
    // A credit that reaches the share price makes the comparison meaningless.
    if (i.shortCredit >= i.spot) return false;

    final d = i.leapsDelta;
    if (d != null && (d <= 0 || d > 1)) return false;
    return true;
  }
}
