import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/position_sizing_engine.dart';

void main() {
  const engine = PositionSizingEngine();

  group('CSP sizing', () {
    test('sizes by capital cap on a mid-size account', () {
      final r = engine.size(
        const PositionSizingInput(
          strategy: SizingStrategy.csp,
          strike: 20,
          premium: 0.50,
          accountSize: 10000,
          buyingPower: 10000,
          maxCapitalPercent: 50,
          maxLossPercent: 50,
        ),
      )!;

      expect(r.capitalPerContract, 2000);
      expect(r.maxLossPerContract, 1950);
      expect(r.premiumPerContract, 50);
      expect(r.returnOnCapitalPercent, closeTo(2.5, 1e-9));
      expect(r.maxContractsByCapital, 2);
      expect(r.recommendedContracts, 2);
      expect(r.totalCapital, 4000);
      expect(r.capitalPercentOfAccount, closeTo(40, 1e-9));
    });

    test('buying power can be tighter than the percent cap', () {
      final r = engine.size(
        const PositionSizingInput(
          strategy: SizingStrategy.csp,
          strike: 20,
          premium: 0.50,
          accountSize: 10000,
          buyingPower: 2500,
          maxCapitalPercent: 90,
          maxLossPercent: 90,
        ),
      )!;

      expect(r.maxContractsByCapital, 1);
      expect(r.recommendedContracts, 1);
    });

    test('risk limit binds when max loss % is small', () {
      final r = engine.size(
        const PositionSizingInput(
          strategy: SizingStrategy.csp,
          strike: 10,
          premium: 0.20,
          accountSize: 10000,
          buyingPower: 10000,
          maxCapitalPercent: 90,
          maxLossPercent: 10,
        ),
      )!;

      // Max loss per contract = 980; risk budget = 1000 -> 1 contract.
      expect(r.maxContractsByRisk, 1);
      expect(r.maxContractsByCapital, 9);
      expect(r.recommendedContracts, 1);
      expect(r.limitingFactor, SizingLimit.risk);
    });

    test('recommends zero and explains when one contract is too big', () {
      final r = engine.size(
        const PositionSizingInput(
          strategy: SizingStrategy.csp,
          strike: 50,
          premium: 1.0,
          accountSize: 3000,
          buyingPower: 3000,
          maxCapitalPercent: 30,
        ),
      )!;

      expect(r.recommendedContracts, 0);
      expect(r.totalCapital, 0);
      expect(r.minAccountForOneContract, closeTo(5000 / 0.30, 1e-6));
      expect(r.warnings, isNotEmpty);
    });

    test('flags insufficient buying power', () {
      final r = engine.size(
        const PositionSizingInput(
          strategy: SizingStrategy.csp,
          strike: 50,
          premium: 1.0,
          accountSize: 100000,
          buyingPower: 1000,
        ),
      )!;

      expect(r.recommendedContracts, 0);
      expect(r.warnings.first, contains('buying power'));
    });
  });

  group('Credit spread sizing', () {
    test('uses width minus credit as capital and max loss', () {
      final r = engine.size(
        const PositionSizingInput(
          strategy: SizingStrategy.creditSpread,
          strike: 50,
          spreadWidth: 5,
          premium: 1.20,
          accountSize: 5000,
          buyingPower: 5000,
          maxCapitalPercent: 40,
          maxLossPercent: 20,
        ),
      )!;

      expect(r.capitalPerContract, closeTo(380, 1e-9));
      expect(r.maxLossPerContract, closeTo(380, 1e-9));
      // Capital budget 2000 -> 5; risk budget 1000 -> 2.
      expect(r.maxContractsByCapital, 5);
      expect(r.maxContractsByRisk, 2);
      expect(r.recommendedContracts, 2);
      expect(r.totalPremium, closeTo(240, 1e-9));
    });
  });

  group('validation', () {
    test('rejects a credit at or above spread width', () {
      expect(
        engine.size(
          const PositionSizingInput(
            strategy: SizingStrategy.creditSpread,
            strike: 50,
            spreadWidth: 5,
            premium: 5,
            accountSize: 5000,
            buyingPower: 5000,
          ),
        ),
        isNull,
      );
    });

    test('rejects non-positive account size or strike', () {
      expect(
        engine.size(
          const PositionSizingInput(
            strategy: SizingStrategy.csp,
            strike: 0,
            premium: 1,
            accountSize: 5000,
            buyingPower: 5000,
          ),
        ),
        isNull,
      );
      expect(
        engine.size(
          const PositionSizingInput(
            strategy: SizingStrategy.csp,
            strike: 10,
            premium: 1,
            accountSize: 0,
            buyingPower: 0,
          ),
        ),
        isNull,
      );
    });
  });

  group('CSP strike ladder', () {
    test('computes capital and yield per strike, sorted, with affordability',
        () {
      final rows = engine.cspLadder(
        strikesAndPremiums: const [
          MapEntry(30.0, 0.90),
          MapEntry(10.0, 0.20),
          MapEntry(20.0, 0.50),
        ],
        buyingPower: 2500,
      );

      expect(rows.map((r) => r.strike), [10.0, 20.0, 30.0]);
      expect(rows[0].capitalPerContract, 1000);
      expect(rows[0].returnOnCapitalPercent, closeTo(2.0, 1e-9));
      expect(rows[1].affordable, isTrue);
      expect(rows[2].affordable, isFalse);
    });
  });
}
