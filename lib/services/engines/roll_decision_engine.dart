/// Pure-Dart roll-vs-assignment analysis for short puts and short calls.
///
/// All option prices are per share. Dollar fields ending in "PerContract"
/// have the contract multiplier applied.
library;

import 'position_sizing_engine.dart' show kContractMultiplier;

enum RollSide { shortPut, shortCall }

enum RollVerdict { roll, hold, takeAssignment }

class RollCandidate {
  final double newStrike;

  /// Days to expiration of the new option.
  final int newDte;

  /// Price received per share for selling the new option.
  final double newCredit;

  const RollCandidate({
    required this.newStrike,
    required this.newDte,
    required this.newCredit,
  });
}

class RollInput {
  final RollSide side;
  final double strike;
  final int dte;
  final double underlyingPrice;

  /// Cost per share to buy back the current short option.
  final double buybackPrice;

  /// Credit per share originally received when the current option was sold.
  final double originalPremium;

  final List<RollCandidate> candidates;

  /// Extra collateral you can post. Only matters for puts rolled to a higher
  /// strike.
  final double availableBuyingPower;

  const RollInput({
    required this.side,
    required this.strike,
    required this.dte,
    required this.underlyingPrice,
    required this.buybackPrice,
    required this.originalPremium,
    required this.candidates,
    this.availableBuyingPower = double.infinity,
  });
}

class RollCandidateResult {
  final RollCandidate candidate;

  /// New credit minus buyback, per share. Negative means a debit roll.
  final double netCredit;
  final double netCreditPerContract;

  /// Put: your effective share cost basis if the new put is later assigned.
  /// Call: your effective sale price if the new call is later assigned.
  final double effectivePrice;

  /// How much better (per share) this is than taking assignment now.
  final double improvementVsAssignment;

  final int extraDays;
  final double improvementPerExtraDay;

  /// Change in collateral per contract (puts only; negative frees capital).
  final double capitalDeltaPerContract;
  final bool affordable;

  /// False when the candidate cannot be evaluated as a roll (see [notes]).
  final bool eligible;
  final List<String> notes;

  const RollCandidateResult({
    required this.candidate,
    required this.netCredit,
    required this.netCreditPerContract,
    required this.effectivePrice,
    required this.improvementVsAssignment,
    required this.extraDays,
    required this.improvementPerExtraDay,
    required this.capitalDeltaPerContract,
    required this.affordable,
    required this.eligible,
    required this.notes,
  });
}

class RollResult {
  final RollVerdict verdict;
  final String reason;
  final bool inTheMoney;
  final double inTheMoneyPercent;
  final double premiumCapturedPercent;

  /// Put: cost basis if assigned now. Call: sale price if called away now.
  final double assignmentPrice;

  /// Candidate results in the same order as the input.
  final List<RollCandidateResult> candidates;

  /// Index into [candidates] of the recommended roll, if any.
  final int? bestIndex;

  const RollResult({
    required this.verdict,
    required this.reason,
    required this.inTheMoney,
    required this.inTheMoneyPercent,
    required this.premiumCapturedPercent,
    required this.assignmentPrice,
    required this.candidates,
    required this.bestIndex,
  });
}

class RollDecisionEngine {
  const RollDecisionEngine();

  /// Returns null when the inputs do not describe a valid position.
  RollResult? analyze(RollInput i) {
    if (i.strike <= 0 ||
        i.underlyingPrice <= 0 ||
        i.buybackPrice < 0 ||
        i.originalPremium < 0 ||
        i.dte < 0 ||
        i.candidates.isEmpty) {
      return null;
    }

    final isPut = i.side == RollSide.shortPut;
    final itm = isPut
        ? i.underlyingPrice < i.strike
        : i.underlyingPrice > i.strike;
    final itmPercent = !itm
        ? 0.0
        : (isPut
                  ? i.strike - i.underlyingPrice
                  : i.underlyingPrice - i.strike) /
              i.strike *
              100;
    final captured = i.originalPremium > 0
        ? (i.originalPremium - i.buybackPrice) / i.originalPremium * 100
        : 0.0;

    // Put assignment: you buy at strike, premium lowers your basis.
    // Call assignment: you sell at strike, premium adds to your proceeds.
    final assignmentPrice = isPut
        ? i.strike - i.originalPremium
        : i.strike + i.originalPremium;

    final results = [
      for (final c in i.candidates) _evaluate(i, c, assignmentPrice),
    ];

    int? best;
    for (var n = 0; n < results.length; n++) {
      final r = results[n];
      if (!r.eligible ||
          !r.affordable ||
          r.netCredit < 0 ||
          r.improvementVsAssignment <= 0) {
        continue;
      }
      if (best == null ||
          r.improvementPerExtraDay > results[best].improvementPerExtraDay) {
        best = n;
      }
    }

    final RollVerdict verdict;
    final String reason;
    if (!itm) {
      verdict = RollVerdict.hold;
      reason =
          'The option is out of the money, so there is nothing to defend. '
          '${captured.toStringAsFixed(0)}% of the premium is captured.';
      best = null;
    } else if (best != null) {
      verdict = RollVerdict.roll;
      final r = results[best];
      reason =
          'Rolling for a \$${r.netCredit.toStringAsFixed(2)} credit per share '
          '${isPut ? 'lowers your cost basis' : 'raises your sale price'} to '
          '\$${r.effectivePrice.toStringAsFixed(2)} versus '
          '\$${assignmentPrice.toStringAsFixed(2)} if assigned now.';
    } else {
      verdict = RollVerdict.takeAssignment;
      reason =
          'No credit roll beats assignment. Paying a debit or moving to a '
          'worse strike only delays the outcome.';
    }

    return RollResult(
      verdict: verdict,
      reason: reason,
      inTheMoney: itm,
      inTheMoneyPercent: itmPercent,
      premiumCapturedPercent: captured,
      assignmentPrice: assignmentPrice,
      candidates: results,
      bestIndex: best,
    );
  }

  RollCandidateResult _evaluate(
    RollInput i,
    RollCandidate c,
    double assignmentPrice,
  ) {
    final isPut = i.side == RollSide.shortPut;
    final net = c.newCredit - i.buybackPrice;
    final extraDays = c.newDte - i.dte;
    final notes = <String>[];

    var eligible = true;
    if (c.newStrike <= 0 || c.newCredit < 0 || c.newDte <= 0) {
      eligible = false;
      notes.add('Invalid strike, credit or expiration.');
    } else if (extraDays <= 0) {
      eligible = false;
      notes.add('New expiration must be later than the current one.');
    }

    final effective = isPut
        ? c.newStrike - i.originalPremium - net
        : c.newStrike + i.originalPremium + net;
    final improvement = isPut
        ? assignmentPrice - effective
        : effective - assignmentPrice;

    final capitalDelta = isPut
        ? (c.newStrike - i.strike) * kContractMultiplier
        : 0.0;
    final affordable = capitalDelta <= i.availableBuyingPower;

    if (net < 0) notes.add('Debit roll: you pay to extend.');
    if (!affordable) {
      notes.add('Needs more collateral than your available buying power.');
    }
    if (isPut ? c.newStrike > i.strike : c.newStrike < i.strike) {
      notes.add(
        isPut
            ? 'Rolling up adds downside risk.'
            : 'Rolling down caps your upside lower.',
      );
    }

    return RollCandidateResult(
      candidate: c,
      netCredit: net,
      netCreditPerContract: net * kContractMultiplier,
      effectivePrice: effective,
      improvementVsAssignment: improvement,
      extraDays: extraDays,
      improvementPerExtraDay: extraDays > 0 ? improvement / extraDays : 0,
      capitalDeltaPerContract: capitalDelta,
      affordable: affordable,
      eligible: eligible,
      notes: notes,
    );
  }
}
