/// Screens an option chain for cash-secured put candidates and ranks them by
/// annualized return on collateral.
///
/// Returns use the bid (the conservative fill) and the full strike as
/// collateral, matching the position sizing tool. A filter you set excludes
/// quotes that are missing the data it needs.
library;

import '../options/option_chain.dart';
import 'position_sizing_engine.dart' show kContractMultiplier;
import 'probability_engine.dart';

class CspCriteria {
  /// Cash available per position. Quotes needing more collateral are skipped.
  final double buyingPower;

  final int minDte;
  final int maxDte;

  /// Highest acceptable chance of assignment, in percent. Null for no limit.
  final double? maxAssignmentPercent;

  /// Lowest acceptable annualized return on collateral, in percent.
  final double minAnnualizedReturnPercent;

  /// Lowest acceptable open interest. Null for no limit.
  final int? minOpenInterest;

  /// Widest acceptable bid-ask spread as a percent of the midpoint. Null for
  /// no limit.
  final double? maxSpreadPercent;

  /// Used when the chance of assignment is estimated from implied volatility.
  final double riskFreeRatePercent;

  const CspCriteria({
    required this.buyingPower,
    this.minDte = 21,
    this.maxDte = 60,
    this.maxAssignmentPercent = 30,
    this.minAnnualizedReturnPercent = 10,
    this.minOpenInterest,
    this.maxSpreadPercent = 15,
    this.riskFreeRatePercent = 4,
  });
}

enum AssignmentSource { delta, impliedVol, unknown }

/// The first check a quote failed, in the order the screener applies them.
enum CspRejection {
  notPut,
  expiryOutOfRange,
  notOutOfTheMoney,
  noBid,
  overBudget,
  thinOpenInterest,
  wideSpread,
  highAssignment,
  unknownAssignment,
  lowReturn,
}

extension CspRejectionLabel on CspRejection {
  String get label => switch (this) {
    CspRejection.notPut => 'not a put',
    CspRejection.expiryOutOfRange => 'expiration outside your range',
    CspRejection.notOutOfTheMoney => 'not out of the money',
    CspRejection.noBid => 'no bid',
    CspRejection.overBudget => 'needs more collateral than you have',
    CspRejection.thinOpenInterest => 'open interest too low or unknown',
    CspRejection.wideSpread => 'spread too wide or unknown',
    CspRejection.highAssignment => 'assignment chance too high',
    CspRejection.unknownAssignment => 'assignment chance unknown',
    CspRejection.lowReturn => 'return too low',
  };
}

class CspCandidate {
  final OptionQuote quote;
  final int dte;

  /// The bid, per share.
  final double credit;

  /// Full strike value, per contract.
  final double collateral;

  final double returnPercent;
  final double annualizedReturnPercent;

  /// Chance of assignment in percent, or null when it cannot be estimated.
  final double? assignmentPercent;
  final AssignmentSource assignmentSource;

  final double breakeven;

  /// How far the breakeven sits below the stock price, as a percent of it.
  final double cushionPercent;

  final double? spreadPercent;
  final int contractsAffordable;

  const CspCandidate({
    required this.quote,
    required this.dte,
    required this.credit,
    required this.collateral,
    required this.returnPercent,
    required this.annualizedReturnPercent,
    required this.assignmentPercent,
    required this.assignmentSource,
    required this.breakeven,
    required this.cushionPercent,
    required this.spreadPercent,
    required this.contractsAffordable,
  });
}

class CspScreenResult {
  final List<CspCandidate> candidates;
  final int evaluated;
  final Map<CspRejection, int> rejections;

  const CspScreenResult({
    required this.candidates,
    required this.evaluated,
    required this.rejections,
  });
}

class CspScreenerEngine {
  const CspScreenerEngine();

  static const _probability = ProbabilityEngine();

  /// Returns null when the snapshot or criteria are invalid.
  CspScreenResult? screen(ChainSnapshot snapshot, CspCriteria c) {
    if (snapshot.spot <= 0 || c.buyingPower < 0) return null;
    if (c.minDte < 0 || c.maxDte < c.minDte) return null;

    final candidates = <CspCandidate>[];
    final rejections = <CspRejection, int>{};

    for (final q in snapshot.quotes) {
      final result = _evaluate(snapshot, q, c);
      if (result is CspCandidate) {
        candidates.add(result);
      } else if (result is CspRejection) {
        rejections[result] = (rejections[result] ?? 0) + 1;
      }
    }

    candidates.sort((a, b) {
      final byReturn = b.annualizedReturnPercent.compareTo(
        a.annualizedReturnPercent,
      );
      if (byReturn != 0) return byReturn;
      final byRisk = (a.assignmentPercent ?? double.infinity).compareTo(
        b.assignmentPercent ?? double.infinity,
      );
      if (byRisk != 0) return byRisk;
      return a.quote.strike.compareTo(b.quote.strike);
    });

    return CspScreenResult(
      candidates: candidates,
      evaluated: snapshot.quotes.length,
      rejections: rejections,
    );
  }

  /// Returns a [CspCandidate] when the quote passes, otherwise the first
  /// [CspRejection] it hit.
  Object _evaluate(ChainSnapshot snap, OptionQuote q, CspCriteria c) {
    if (q.right != OptionRight.put) return CspRejection.notPut;

    final dte = snap.dte(q);
    if (dte < c.minDte || dte > c.maxDte || dte <= 0) {
      return CspRejection.expiryOutOfRange;
    }
    if (q.strike >= snap.spot) return CspRejection.notOutOfTheMoney;
    if (q.bid <= 0) return CspRejection.noBid;

    final collateral = q.strike * kContractMultiplier;
    if (collateral > c.buyingPower) return CspRejection.overBudget;

    final minOi = c.minOpenInterest;
    if (minOi != null && (q.openInterest == null || q.openInterest! < minOi)) {
      return CspRejection.thinOpenInterest;
    }

    final maxSpread = c.maxSpreadPercent;
    final spread = q.spreadPercent;
    if (maxSpread != null && (spread == null || spread > maxSpread)) {
      return CspRejection.wideSpread;
    }

    double? assignment;
    var source = AssignmentSource.unknown;
    if (q.delta != null) {
      assignment = q.delta! * 100;
      source = AssignmentSource.delta;
    } else if (q.impliedVolPercent != null) {
      final p = _probability.analyze(
        ProbabilityInput(
          side: ProbabilitySide.shortPut,
          spot: snap.spot,
          shortStrike: q.strike,
          credit: q.bid,
          dte: dte,
          impliedVolPercent: q.impliedVolPercent!,
          riskFreeRatePercent: c.riskFreeRatePercent,
        ),
      );
      if (p != null) {
        assignment = p.probabilityInTheMoney * 100;
        source = AssignmentSource.impliedVol;
      }
    }

    final maxAssignment = c.maxAssignmentPercent;
    if (maxAssignment != null) {
      if (assignment == null) return CspRejection.unknownAssignment;
      if (assignment > maxAssignment) return CspRejection.highAssignment;
    }

    final returnPercent = q.bid / q.strike * 100;
    final annualized = returnPercent * 365 / dte;
    if (annualized < c.minAnnualizedReturnPercent) {
      return CspRejection.lowReturn;
    }

    final breakeven = q.strike - q.bid;
    return CspCandidate(
      quote: q,
      dte: dte,
      credit: q.bid,
      collateral: collateral,
      returnPercent: returnPercent,
      annualizedReturnPercent: annualized,
      assignmentPercent: assignment,
      assignmentSource: source,
      breakeven: breakeven,
      cushionPercent: (snap.spot - breakeven) / snap.spot * 100,
      spreadPercent: spread,
      contractsAffordable: (c.buyingPower / collateral).floor(),
    );
  }
}
