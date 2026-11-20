import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/probability_engine.dart';

void main() {
  const engine = ProbabilityEngine();

  ProbabilityInput put({
    double strike = 95,
    double credit = 1.20,
    int dte = 30,
    double iv = 30,
    double rate = 0,
    ProbabilitySide side = ProbabilitySide.shortPut,
    double? longStrike,
  }) => ProbabilityInput(
    side: side,
    spot: 100,
    shortStrike: strike,
    longStrike: longStrike,
    credit: credit,
    dte: dte,
    impliedVolPercent: iv,
    riskFreeRatePercent: rate,
  );

  group('normalCdf', () {
    test('matches known values', () {
      expect(ProbabilityEngine.normalCdf(0), closeTo(0.5, 1e-6));
      expect(ProbabilityEngine.normalCdf(1.96), closeTo(0.9750021, 1e-6));
      expect(ProbabilityEngine.normalCdf(-1), closeTo(0.1586553, 1e-6));
      expect(ProbabilityEngine.normalCdf(8), closeTo(1.0, 1e-9));
      expect(ProbabilityEngine.normalCdf(-8), closeTo(0.0, 1e-9));
    });
  });

  group('short put', () {
    test('matches independently computed probabilities', () {
      final r = engine.analyze(put())!;

      expect(r.probabilityInTheMoney, closeTo(0.2900, 1e-4));
      expect(r.probabilityMaxProfit, closeTo(0.7100, 1e-4));
      expect(r.breakeven, closeTo(93.80, 1e-9));
      expect(r.probabilityOfProfit, closeTo(0.7584, 1e-4));
      expect(r.expectedMove, closeTo(8.6007, 1e-3));
      expect(r.lowerBound, closeTo(91.399, 1e-3));
      expect(r.upperBound, closeTo(108.601, 1e-3));
      expect(r.strikeDistancePercent, closeTo(5.0, 1e-9));
      expect(r.breakevenDistancePercent, closeTo(6.2, 1e-9));
    });

    test('reports risk in dollars per contract', () {
      final r = engine.analyze(put())!;

      expect(r.maxProfitPerContract, closeTo(120, 1e-9));
      expect(r.maxLossPerContract, closeTo(9380, 1e-9));
      expect(r.returnOnRiskPercent, closeTo(120 / 9380 * 100, 1e-9));
    });

    test('a positive risk-free rate lowers assignment probability', () {
      final zero = engine.analyze(put())!;
      final withRate = engine.analyze(put(rate: 4))!;

      expect(withRate.probabilityInTheMoney, closeTo(0.2771, 1e-4));
      expect(
        withRate.probabilityInTheMoney,
        lessThan(zero.probabilityInTheMoney),
      );
    });

    test('moves the way you would expect', () {
      final base = engine.analyze(put())!;

      expect(
        engine.analyze(put(strike: 90))!.probabilityInTheMoney,
        lessThan(base.probabilityInTheMoney),
      );
      expect(
        engine.analyze(put(iv: 45))!.probabilityInTheMoney,
        greaterThan(base.probabilityInTheMoney),
      );
      expect(
        engine.analyze(put(credit: 2.5))!.probabilityOfProfit,
        greaterThan(base.probabilityOfProfit),
      );
      expect(
        engine.analyze(put(strike: 90))!.strikeSigmaDistance,
        greaterThan(base.strikeSigmaDistance),
      );
    });
  });

  group('short call', () {
    test('matches independently computed probabilities', () {
      final r = engine.analyze(
        put(strike: 105, credit: 1.0, side: ProbabilitySide.shortCall),
      )!;

      expect(r.probabilityInTheMoney, closeTo(0.2708, 1e-4));
      expect(r.breakeven, closeTo(106.0, 1e-9));
      expect(r.probabilityOfProfit, closeTo(0.7644, 1e-4));
      expect(r.maxLossPerContract, isNull);
      expect(r.returnOnRiskPercent, isNull);
    });

    test('call and put in-the-money chances at one strike sum to one', () {
      final c = engine.analyze(
        put(strike: 100, credit: 1, side: ProbabilitySide.shortCall),
      )!;
      final p = engine.analyze(put(strike: 100, credit: 1))!;

      expect(
        c.probabilityInTheMoney + p.probabilityInTheMoney,
        closeTo(1, 1e-9),
      );
    });
  });

  group('credit spreads', () {
    test('put credit spread uses width minus credit as max loss', () {
      final r = engine.analyze(
        put(side: ProbabilitySide.putCreditSpread, longStrike: 90),
      )!;

      expect(r.maxProfitPerContract, closeTo(120, 1e-9));
      expect(r.maxLossPerContract, closeTo(380, 1e-9));
      expect(r.returnOnRiskPercent, closeTo(120 / 380 * 100, 1e-9));
      expect(r.probabilityOfProfit, closeTo(0.7584, 1e-4));
    });

    test('call credit spread uses the strike above', () {
      final r = engine.analyze(
        put(
          strike: 105,
          credit: 1.0,
          side: ProbabilitySide.callCreditSpread,
          longStrike: 110,
        ),
      )!;

      expect(r.maxLossPerContract, closeTo(400, 1e-9));
      expect(r.breakeven, closeTo(106, 1e-9));
    });
  });

  group('validation', () {
    test('rejects bad inputs', () {
      expect(engine.analyze(put(dte: 0)), isNull);
      expect(engine.analyze(put(iv: 0)), isNull);
      expect(engine.analyze(put(credit: -1)), isNull);
      expect(engine.analyze(put(strike: 0)), isNull);
      expect(engine.analyze(put(credit: 95)), isNull);
    });

    test('rejects malformed spreads', () {
      // Missing long strike, long strike on the wrong side, credit >= width.
      expect(
        engine.analyze(put(side: ProbabilitySide.putCreditSpread)),
        isNull,
      );
      expect(
        engine.analyze(
          put(side: ProbabilitySide.putCreditSpread, longStrike: 100),
        ),
        isNull,
      );
      expect(
        engine.analyze(
          put(side: ProbabilitySide.putCreditSpread, longStrike: 90, credit: 5),
        ),
        isNull,
      );
    });
  });
}
