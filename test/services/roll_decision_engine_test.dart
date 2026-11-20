import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/roll_decision_engine.dart';

void main() {
  const engine = RollDecisionEngine();

  RollInput putInput({
    double underlying = 47,
    double buyback = 3.50,
    List<RollCandidate>? candidates,
    double buyingPower = double.infinity,
  }) => RollInput(
    side: RollSide.shortPut,
    strike: 50,
    dte: 5,
    underlyingPrice: underlying,
    buybackPrice: buyback,
    originalPremium: 1.0,
    candidates:
        candidates ??
        const [RollCandidate(newStrike: 47, newDte: 60, newCredit: 4.20)],
    availableBuyingPower: buyingPower,
  );

  group('short put', () {
    test('recommends a credit roll down and out that lowers basis', () {
      final r = engine.analyze(putInput())!;

      expect(r.inTheMoney, isTrue);
      expect(r.inTheMoneyPercent, closeTo(6.0, 1e-9));
      expect(r.assignmentPrice, closeTo(49.0, 1e-9));
      expect(r.verdict, RollVerdict.roll);
      expect(r.bestIndex, 0);

      final c = r.candidates.first;
      expect(c.netCredit, closeTo(0.70, 1e-9));
      expect(c.netCreditPerContract, closeTo(70, 1e-9));
      expect(c.effectivePrice, closeTo(45.3, 1e-9));
      expect(c.improvementVsAssignment, closeTo(3.7, 1e-9));
      expect(c.extraDays, 55);
      expect(c.capitalDeltaPerContract, closeTo(-300, 1e-9));
    });

    test('takes assignment when only debit rolls are available', () {
      final r = engine.analyze(
        putInput(
          candidates: const [
            RollCandidate(newStrike: 47, newDte: 60, newCredit: 3.00),
          ],
        ),
      )!;

      expect(r.candidates.first.netCredit, closeTo(-0.5, 1e-9));
      expect(r.verdict, RollVerdict.takeAssignment);
      expect(r.bestIndex, isNull);
    });

    test('holds when out of the money', () {
      final r = engine.analyze(putInput(underlying: 52, buyback: 0.40))!;

      expect(r.inTheMoney, isFalse);
      expect(r.inTheMoneyPercent, 0);
      expect(r.premiumCapturedPercent, closeTo(60, 1e-9));
      expect(r.verdict, RollVerdict.hold);
      expect(r.bestIndex, isNull);
    });

    test('picks the roll with the best improvement per extra day', () {
      final r = engine.analyze(
        putInput(
          candidates: const [
            RollCandidate(newStrike: 47, newDte: 35, newCredit: 4.20),
            RollCandidate(newStrike: 47, newDte: 65, newCredit: 4.60),
          ],
        ),
      )!;

      // A: 3.7 over 30 days. B: 4.1 over 60 days.
      expect(r.verdict, RollVerdict.roll);
      expect(r.bestIndex, 0);
      expect(
        r.candidates[0].improvementPerExtraDay,
        greaterThan(r.candidates[1].improvementPerExtraDay),
      );
    });

    test('rejects a candidate that does not extend the expiration', () {
      final r = engine.analyze(
        putInput(
          candidates: const [
            RollCandidate(newStrike: 47, newDte: 5, newCredit: 4.20),
          ],
        ),
      )!;

      expect(r.candidates.first.eligible, isFalse);
      expect(r.verdict, RollVerdict.takeAssignment);
    });

    test('flags a roll up that needs more collateral than available', () {
      final r = engine.analyze(
        putInput(
          buyingPower: 100,
          candidates: const [
            RollCandidate(newStrike: 52, newDte: 60, newCredit: 6.00),
          ],
        ),
      )!;

      final c = r.candidates.first;
      expect(c.capitalDeltaPerContract, closeTo(200, 1e-9));
      expect(c.affordable, isFalse);
      expect(c.notes.join(' '), contains('buying power'));
      expect(r.verdict, RollVerdict.takeAssignment);
    });
  });

  group('short call', () {
    test('recommends a credit roll up and out that raises sale price', () {
      final r = engine.analyze(
        const RollInput(
          side: RollSide.shortCall,
          strike: 50,
          dte: 4,
          underlyingPrice: 52,
          buybackPrice: 2.60,
          originalPremium: 0.80,
          candidates: [
            RollCandidate(newStrike: 53, newDte: 45, newCredit: 3.40),
          ],
        ),
      )!;

      expect(r.inTheMoney, isTrue);
      expect(r.inTheMoneyPercent, closeTo(4.0, 1e-9));
      expect(r.assignmentPrice, closeTo(50.8, 1e-9));
      expect(r.verdict, RollVerdict.roll);

      final c = r.candidates.first;
      expect(c.netCredit, closeTo(0.80, 1e-9));
      expect(c.effectivePrice, closeTo(54.6, 1e-9));
      expect(c.improvementVsAssignment, closeTo(3.8, 1e-9));
      expect(c.capitalDeltaPerContract, 0);
    });
  });

  group('validation', () {
    test('returns null for invalid input', () {
      expect(engine.analyze(putInput(candidates: const [])), isNull);
      expect(
        engine.analyze(
          const RollInput(
            side: RollSide.shortPut,
            strike: 0,
            dte: 5,
            underlyingPrice: 47,
            buybackPrice: 1,
            originalPremium: 1,
            candidates: [
              RollCandidate(newStrike: 45, newDte: 30, newCredit: 2),
            ],
          ),
        ),
        isNull,
      );
    });
  });
}
