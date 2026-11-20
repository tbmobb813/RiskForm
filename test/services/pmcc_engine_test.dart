import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/pmcc_engine.dart';

void main() {
  const engine = PmccEngine();

  PmccInput input({
    double spot = 100,
    double leapsStrike = 70,
    double leapsCost = 34,
    int leapsDte = 400,
    double? delta = 0.85,
    double shortStrike = 105,
    double credit = 1.5,
    int shortDte = 30,
    double premiums = 5,
  }) => PmccInput(
    spot: spot,
    leapsStrike: leapsStrike,
    leapsCost: leapsCost,
    leapsDte: leapsDte,
    leapsDelta: delta,
    shortStrike: shortStrike,
    shortCredit: credit,
    shortDte: shortDte,
    premiumsCollected: premiums,
  );

  group('cost and profit', () {
    test('matches independently computed values', () {
      final r = engine.analyze(input())!;

      expect(r.syntheticStockCost, closeTo(104, 1e-9));
      expect(r.netDebit, closeTo(27.5, 1e-9));
      expect(r.effectiveBasis, closeTo(97.5, 1e-9));
      expect(r.width, closeTo(35, 1e-9));
      expect(r.maxProfitPerShare, closeTo(7.5, 1e-9));
      expect(r.maxProfitPerContract, closeTo(750, 1e-9));
      expect(r.maxLossPerContract, closeTo(2750, 1e-9));
      expect(r.warnings, isEmpty);
    });

    test('splits the LEAPS price into intrinsic and time value', () {
      final r = engine.analyze(input())!;

      expect(r.intrinsicValue, closeTo(30, 1e-9));
      expect(r.extrinsicValue, closeTo(4, 1e-9));
      expect(r.extrinsicPercentOfCost, closeTo(11.7647, 1e-3));
    });

    test('compares capital and cycle return with owning shares', () {
      final r = engine.analyze(input())!;

      expect(r.sharesCapitalPerContract, closeTo(10000, 1e-9));
      expect(r.leapsCapitalPerContract, closeTo(3400, 1e-9));
      expect(r.capitalSavingsPercent, closeTo(66, 1e-9));
      expect(r.cycleReturnPercent, closeTo(7.6923, 1e-3));
      expect(r.sharesCycleReturnPercent, closeTo(6.5990, 1e-3));
    });

    test('recovered cost shows no downside', () {
      final r = engine.analyze(input(premiums: 40))!;

      expect(r.netDebit, lessThan(0));
      expect(r.maxLossPerContract, 0);
    });
  });

  group('warnings', () {
    test('flags a low-delta LEAPS', () {
      final r = engine.analyze(input(delta: 0.6))!;
      expect(r.warnings.join(' '), contains('delta'));
    });

    test('flags a LEAPS with too little time left', () {
      final r = engine.analyze(input(leapsDte: 200))!;
      expect(r.warnings.join(' '), contains('9 months'));
    });

    test('flags too much time value', () {
      final r = engine.analyze(input(leapsCost: 45))!;
      expect(r.extrinsicPercentOfCost, closeTo(33.33, 1e-2));
      expect(r.warnings.join(' '), contains('Time value'));
    });

    test('flags a LEAPS that is not in the money', () {
      final r = engine.analyze(input(spot: 65, shortStrike: 90))!;
      expect(r.intrinsicValue, 0);
      expect(r.warnings.join(' '), contains('not in the money'));
    });

    test('flags a strike gap that cannot cover the net cost', () {
      final r = engine.analyze(input(shortStrike: 100, premiums: 0))!;

      expect(r.width, closeTo(30, 1e-9));
      expect(r.netDebit, closeTo(32.5, 1e-9));
      expect(r.warnings.join(' '), contains('lose money'));
    });

    test('flags a thin strike gap without calling it a loss', () {
      final r = engine.analyze(input(premiums: 2))!;

      expect(r.warnings.join(' '), contains('thin'));
      expect(r.warnings.join(' '), isNot(contains('lose money')));
    });

    test('flags a short call that is in the money', () {
      final r = engine.analyze(input(spot: 110))!;

      expect(r.shortInTheMoney, isTrue);
      expect(r.warnings.join(' '), contains('in the money'));
      expect(r.shortStrikeDistancePercent, closeTo(4.545, 1e-3));
    });
  });

  group('validation', () {
    test('rejects structures that are not a poor man covered call', () {
      expect(engine.analyze(input(shortStrike: 70)), isNull);
      expect(engine.analyze(input(shortStrike: 60)), isNull);
      expect(engine.analyze(input(shortDte: 400)), isNull);
      expect(engine.analyze(input(shortDte: 500)), isNull);
    });

    test('rejects bad numbers', () {
      expect(engine.analyze(input(spot: 0)), isNull);
      expect(engine.analyze(input(leapsCost: 0)), isNull);
      expect(engine.analyze(input(credit: -1)), isNull);
      expect(engine.analyze(input(premiums: -1)), isNull);
      expect(engine.analyze(input(delta: 0)), isNull);
      expect(engine.analyze(input(delta: 1.2)), isNull);
    });

    test('delta is optional', () {
      final r = engine.analyze(input(delta: null))!;
      expect(r.warnings, isEmpty);
    });
  });
}
