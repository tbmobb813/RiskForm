import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/capital_allocation_engine.dart';

void main() {
  const engine = CapitalAllocationEngine();

  const aapl = AllocationHolding(
    symbol: 'AAPL',
    strategy: HoldingStrategy.csp,
    capital: 5000,
    premium: 100,
    originalDays: 30,
    dte: 10,
  );
  const ford = AllocationHolding(
    symbol: 'F',
    strategy: HoldingStrategy.csp,
    capital: 2000,
    premium: 30,
    originalDays: 30,
    dte: 25,
  );

  AllocationInput input({
    List<AllocationHolding> holdings = const [aapl, ford],
    double freeCash = 2500,
  }) => AllocationInput(
    accountSize: 10000,
    freeCash: freeCash,
    holdings: holdings,
  );

  test('computes deployment, returns and opportunity cost', () {
    final r = engine.analyze(input())!;

    expect(r.totalDeployed, 7000);
    expect(r.deployedPercent, closeTo(70, 1e-9));
    expect(r.freeCashPercent, closeTo(25, 1e-9));
    expect(r.totalPremium, 130);

    final a = r.holdings[0];
    expect(a.percentOfAccount, closeTo(50, 1e-9));
    expect(a.annualizedReturnPercent, closeTo(24.3333, 1e-3));
    expect(a.opportunityCost, closeTo(16.4384, 1e-3));
    expect(a.excessOverBenchmark, closeTo(83.5616, 1e-3));
    expect(a.underearning, isFalse);

    expect(r.holdings[1].annualizedReturnPercent, closeTo(18.25, 1e-9));
    expect(r.weightedAnnualizedReturnPercent, closeTo(22.595, 1e-3));
    expect(r.totalOpportunityCost, closeTo(23.0137, 1e-3));
  });

  test('flags concentration and sorts symbols by exposure', () {
    final r = engine.analyze(input())!;

    expect(r.symbols.map((s) => s.symbol), ['AAPL', 'F']);
    expect(r.symbols.first.overLimit, isTrue);
    expect(r.symbols.last.overLimit, isFalse);
    expect(r.warnings.single, contains('AAPL is 50%'));
  });

  test('groups the same symbol case-insensitively across positions', () {
    final r = engine.analyze(
      input(
        holdings: const [
          aapl,
          AllocationHolding(
            symbol: 'aapl',
            strategy: HoldingStrategy.coveredCall,
            capital: 1000,
            premium: 20,
            originalDays: 30,
            dte: 5,
          ),
        ],
      ),
    )!;

    expect(r.symbols.length, 1);
    expect(r.symbols.single.symbol, 'AAPL');
    expect(r.symbols.single.capital, 6000);
    expect(r.capitalByStrategy[HoldingStrategy.csp], 5000);
    expect(r.capitalByStrategy[HoldingStrategy.coveredCall], 1000);
  });

  test('reports when capital frees up', () {
    final r = engine.analyze(input())!;

    expect(r.capitalFreedWithin[7], 0);
    expect(r.capitalFreedWithin[14], 5000);
    expect(r.capitalFreedWithin[30], 7000);
  });

  test('budget for a new position respects free cash and symbol cap', () {
    expect(engine.analyze(input())!.newPositionBudget, 2500);
    expect(engine.analyze(input(freeCash: 6000))!.newPositionBudget, 3000);
  });

  test('warns about a thin cash reserve', () {
    final r = engine.analyze(input(freeCash: 500))!;

    expect(r.warnings.join(' '), contains('below the 10% reserve'));
  });

  test('flags a position that earned less than idle cash', () {
    final r = engine.analyze(
      input(
        holdings: const [
          AllocationHolding(
            symbol: 'SPY',
            strategy: HoldingStrategy.csp,
            capital: 5000,
            premium: 5,
            originalDays: 30,
            dte: 10,
          ),
        ],
      ),
    )!;

    expect(r.holdings.single.underearning, isTrue);
    expect(r.warnings.join(' '), contains('earned less than idle cash'));
  });

  test('handles an empty portfolio and ignores zero-capital rows', () {
    final empty = engine.analyze(input(holdings: const []))!;
    expect(empty.totalDeployed, 0);
    expect(empty.weightedAnnualizedReturnPercent, isNull);

    final blank = engine.analyze(
      input(
        holdings: const [
          AllocationHolding(
            symbol: '',
            strategy: HoldingStrategy.other,
            capital: 0,
            premium: 0,
            originalDays: 0,
            dte: 0,
          ),
        ],
      ),
    )!;
    expect(blank.holdings, isEmpty);
  });

  test('returns null for invalid input', () {
    expect(
      engine.analyze(
        const AllocationInput(accountSize: 0, freeCash: 0, holdings: []),
      ),
      isNull,
    );
    expect(
      engine.analyze(
        input(
          holdings: const [
            AllocationHolding(
              symbol: 'X',
              strategy: HoldingStrategy.csp,
              capital: -1,
              premium: 0,
              originalDays: 30,
              dte: 5,
            ),
          ],
        ),
      ),
      isNull,
    );
  });
}
