import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/csp_screener_engine.dart';
import 'package:riskform/services/options/option_chain.dart';

void main() {
  const screener = CspScreenerEngine();
  final asOf = DateTime(2026, 11, 20);
  final exp30 = DateTime.utc(2026, 12, 20);
  final exp45 = DateTime.utc(2027, 1, 4);
  final exp10 = DateTime.utc(2026, 11, 30);

  OptionQuote put(
    double strike,
    DateTime exp,
    double bid, {
    double? ask,
    double? delta,
    double? iv,
    int? oi,
    OptionRight right = OptionRight.put,
  }) => OptionQuote(
    right: right,
    strike: strike,
    expiration: exp,
    bid: bid,
    ask: ask,
    delta: delta,
    impliedVolPercent: iv,
    openInterest: oi,
  );

  // Stock at 100. Reference numbers in the tests were computed separately.
  final a = put(95, exp30, 1.20, ask: 1.30, delta: 0.25, oi: 500);
  final b = put(90, exp30, 0.50, ask: 0.55, delta: 0.12, oi: 800);
  final c = put(98, exp30, 2.40, ask: 2.60, delta: 0.38, oi: 100);
  final d = put(95, exp45, 1.90, ask: 1.95, iv: 30, oi: 400);
  final e = put(105, exp30, 6.0, ask: 6.2, delta: 0.6);
  final f = put(80, exp30, 0, ask: 0.05, delta: 0.03);
  final g = put(95, exp10, 0.60, ask: 0.65, delta: 0.2);
  final call = put(
    105,
    exp30,
    0.9,
    ask: 1.0,
    delta: 0.22,
    right: OptionRight.call,
  );
  final j = put(95, exp30, 1.20);

  ChainSnapshot chain(List<OptionQuote> quotes, {double spot = 100}) =>
      ChainSnapshot(underlying: 'XYZ', spot: spot, asOf: asOf, quotes: quotes);

  final all = [a, b, c, d, e, f, g, call, j];

  const criteria = CspCriteria(
    buyingPower: 10000,
    maxAssignmentPercent: 35,
    minAnnualizedReturnPercent: 10,
    maxSpreadPercent: 15,
  );

  test('ranks passing puts by annualized return and explains the rest', () {
    final r = screener.screen(chain(all), criteria)!;

    expect(r.evaluated, 9);
    expect(r.candidates.map((x) => x.quote), [d, a]);
    expect(r.rejections, {
      CspRejection.notPut: 1,
      CspRejection.expiryOutOfRange: 1,
      CspRejection.notOutOfTheMoney: 1,
      CspRejection.noBid: 1,
      CspRejection.wideSpread: 1,
      CspRejection.highAssignment: 1,
      CspRejection.lowReturn: 1,
    });
  });

  test('computes return, breakeven and affordability', () {
    final r = screener.screen(chain(all), criteria)!;
    final top = r.candidates.last; // quote A

    expect(top.dte, 30);
    expect(top.credit, 1.20);
    expect(top.collateral, 9500);
    expect(top.returnPercent, closeTo(1.2632, 1e-4));
    expect(top.annualizedReturnPercent, closeTo(15.3684, 1e-4));
    expect(top.breakeven, closeTo(93.80, 1e-9));
    expect(top.cushionPercent, closeTo(6.20, 1e-9));
    expect(top.spreadPercent, closeTo(8.0, 1e-9));
    expect(top.contractsAffordable, 1);
    expect(top.assignmentSource, AssignmentSource.delta);
    expect(top.assignmentPercent, closeTo(25, 1e-9));
  });

  test(
    'estimates assignment from implied volatility when delta is missing',
    () {
      final r = screener.screen(chain(all), criteria)!;
      final first = r.candidates.first; // quote D

      expect(first.quote, d);
      expect(first.annualizedReturnPercent, closeTo(16.2222, 1e-4));
      expect(first.assignmentSource, AssignmentSource.impliedVol);
      expect(first.assignmentPercent, closeTo(31.5225, 1e-3));
    },
  );

  test('skips quotes that need more collateral than you have', () {
    final r = screener.screen(
      chain(all),
      const CspCriteria(
        buyingPower: 9400,
        maxAssignmentPercent: 35,
        minAnnualizedReturnPercent: 10,
      ),
    )!;

    expect(r.rejections[CspRejection.overBudget], 4); // A, C, D and J
    expect(r.candidates, isEmpty);
  });

  test('a minimum open interest excludes thin and unknown quotes', () {
    final r = screener.screen(
      chain(all),
      const CspCriteria(
        buyingPower: 10000,
        maxAssignmentPercent: 35,
        minAnnualizedReturnPercent: 10,
        minOpenInterest: 200,
      ),
    )!;

    expect(r.rejections[CspRejection.thinOpenInterest], 2); // C and J
    expect(r.rejections[CspRejection.highAssignment], isNull);
  });

  test('an assignment limit excludes quotes that cannot be estimated', () {
    final r = screener.screen(
      chain([j]),
      const CspCriteria(
        buyingPower: 10000,
        maxAssignmentPercent: 35,
        minAnnualizedReturnPercent: 0,
        maxSpreadPercent: null,
      ),
    )!;

    expect(r.rejections, {CspRejection.unknownAssignment: 1});
  });

  test('without limits, a quote with missing data is kept', () {
    final r = screener.screen(
      chain([j]),
      const CspCriteria(
        buyingPower: 10000,
        maxAssignmentPercent: null,
        minAnnualizedReturnPercent: 0,
        maxSpreadPercent: null,
      ),
    )!;

    final kept = r.candidates.single;
    expect(kept.assignmentPercent, isNull);
    expect(kept.assignmentSource, AssignmentSource.unknown);
    expect(kept.spreadPercent, isNull);
  });

  test('a strike at the stock price is not out of the money', () {
    final r = screener.screen(
      chain([put(100, exp30, 3.0, ask: 3.1, delta: 0.5)]),
      criteria,
    )!;

    expect(r.rejections, {CspRejection.notOutOfTheMoney: 1});
  });

  test('breaks return ties by lower assignment chance', () {
    final safer = put(95, exp30, 1.20, ask: 1.30, delta: 0.15);
    final riskier = put(95, exp30, 1.20, ask: 1.30, delta: 0.30);
    final r = screener.screen(chain([riskier, safer]), criteria)!;

    expect(r.candidates.map((x) => x.assignmentPercent), [15, 30]);
  });

  test('returns null for invalid input', () {
    expect(screener.screen(chain(all, spot: 0), criteria), isNull);
    expect(
      screener.screen(
        chain(all),
        const CspCriteria(buyingPower: 1000, minDte: 40, maxDte: 20),
      ),
      isNull,
    );
    expect(
      screener.screen(chain(all), const CspCriteria(buyingPower: -1)),
      isNull,
    );
  });

  test('every rejection reason has a label', () {
    for (final reason in CspRejection.values) {
      expect(reason.label, isNotEmpty);
    }
  });
}
