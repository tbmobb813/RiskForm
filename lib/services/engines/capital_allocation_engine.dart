/// Pure-Dart capital allocation analysis for a set of open income positions.
///
/// Dollar inputs are totals for the whole position, not per share.
library;

enum HoldingStrategy { csp, coveredCall, creditSpread, other }

extension HoldingStrategyLabel on HoldingStrategy {
  String get label => switch (this) {
    HoldingStrategy.csp => 'Cash-Secured Put',
    HoldingStrategy.coveredCall => 'Covered Call',
    HoldingStrategy.creditSpread => 'Credit Spread',
    HoldingStrategy.other => 'Other',
  };
}

class AllocationHolding {
  final String symbol;
  final HoldingStrategy strategy;

  /// Collateral or capital tied up by this position.
  final double capital;

  /// Total premium collected for this position's full life.
  final double premium;

  /// Length of the trade in days from open to expiration.
  final int originalDays;

  /// Days left until expiration.
  final int dte;

  const AllocationHolding({
    required this.symbol,
    required this.strategy,
    required this.capital,
    required this.premium,
    required this.originalDays,
    required this.dte,
  });
}

class AllocationInput {
  final double accountSize;

  /// Uninvested cash you could put to work now.
  final double freeCash;
  final List<AllocationHolding> holdings;

  /// Annual yield on idle cash (for example a T-bill rate), in percent.
  final double benchmarkAnnualPercent;

  /// Warn when one symbol holds more than this share of the account.
  final double maxSymbolPercent;

  /// Warn when free cash falls below this share of the account.
  final double minCashReservePercent;

  const AllocationInput({
    required this.accountSize,
    required this.freeCash,
    required this.holdings,
    this.benchmarkAnnualPercent = 4.0,
    this.maxSymbolPercent = 30,
    this.minCashReservePercent = 10,
  });
}

class HoldingMetrics {
  final AllocationHolding holding;
  final double percentOfAccount;

  /// Premium annualized over the trade's original length, as a percent of
  /// capital. Null when the trade length is zero.
  final double? annualizedReturnPercent;

  /// What the same capital would have earned at the benchmark over the trade.
  final double opportunityCost;

  /// Premium minus [opportunityCost].
  final double excessOverBenchmark;
  final bool underearning;

  const HoldingMetrics({
    required this.holding,
    required this.percentOfAccount,
    required this.annualizedReturnPercent,
    required this.opportunityCost,
    required this.excessOverBenchmark,
    required this.underearning,
  });
}

class SymbolExposure {
  final String symbol;
  final double capital;
  final double percentOfAccount;
  final bool overLimit;

  const SymbolExposure({
    required this.symbol,
    required this.capital,
    required this.percentOfAccount,
    required this.overLimit,
  });
}

class AllocationResult {
  final double totalDeployed;
  final double deployedPercent;
  final double freeCash;
  final double freeCashPercent;

  /// Capital-weighted annualized return across deployed positions. Null when
  /// nothing is deployed.
  final double? weightedAnnualizedReturnPercent;
  final double totalPremium;
  final double totalOpportunityCost;

  final List<HoldingMetrics> holdings;

  /// Largest exposure first.
  final List<SymbolExposure> symbols;
  final Map<HoldingStrategy, double> capitalByStrategy;

  /// Capital that frees up by each horizon, keyed by number of days.
  final Map<int, double> capitalFreedWithin;

  /// Largest single new position that fits free cash and the symbol cap.
  final double newPositionBudget;

  final List<String> warnings;

  const AllocationResult({
    required this.totalDeployed,
    required this.deployedPercent,
    required this.freeCash,
    required this.freeCashPercent,
    required this.weightedAnnualizedReturnPercent,
    required this.totalPremium,
    required this.totalOpportunityCost,
    required this.holdings,
    required this.symbols,
    required this.capitalByStrategy,
    required this.capitalFreedWithin,
    required this.newPositionBudget,
    required this.warnings,
  });
}

class CapitalAllocationEngine {
  const CapitalAllocationEngine();

  static const freedHorizons = [7, 14, 30];

  /// Returns null when the inputs are invalid. Holdings with zero capital are
  /// ignored.
  AllocationResult? analyze(AllocationInput i) {
    if (i.accountSize <= 0 || i.freeCash < 0) return null;
    for (final h in i.holdings) {
      if (h.capital < 0 || h.premium < 0 || h.originalDays < 0 || h.dte < 0) {
        return null;
      }
    }

    final active = i.holdings.where((h) => h.capital > 0).toList();
    final metrics = <HoldingMetrics>[];
    var deployed = 0.0;
    var premium = 0.0;
    var opportunity = 0.0;
    var annualizedPremium = 0.0;

    for (final h in active) {
      final opp =
          h.capital * i.benchmarkAnnualPercent / 100 * h.originalDays / 365;
      final annualized = h.originalDays > 0
          ? h.premium / h.capital * 365 / h.originalDays * 100
          : null;
      deployed += h.capital;
      premium += h.premium;
      opportunity += opp;
      if (h.originalDays > 0) {
        annualizedPremium += h.premium * 365 / h.originalDays;
      }
      metrics.add(
        HoldingMetrics(
          holding: h,
          percentOfAccount: h.capital / i.accountSize * 100,
          annualizedReturnPercent: annualized,
          opportunityCost: opp,
          excessOverBenchmark: h.premium - opp,
          underearning: h.premium < opp,
        ),
      );
    }

    final bySymbol = <String, double>{};
    final byStrategy = <HoldingStrategy, double>{};
    for (final h in active) {
      final key = h.symbol.trim().toUpperCase();
      bySymbol[key] = (bySymbol[key] ?? 0) + h.capital;
      byStrategy[h.strategy] = (byStrategy[h.strategy] ?? 0) + h.capital;
    }
    final symbols = [
      for (final e in bySymbol.entries)
        SymbolExposure(
          symbol: e.key.isEmpty ? '(unnamed)' : e.key,
          capital: e.value,
          percentOfAccount: e.value / i.accountSize * 100,
          overLimit: e.value / i.accountSize * 100 > i.maxSymbolPercent,
        ),
    ]..sort((a, b) => b.capital.compareTo(a.capital));

    final freed = {
      for (final d in freedHorizons)
        d: active.where((h) => h.dte <= d).fold(0.0, (s, h) => s + h.capital),
    };

    final freePercent = i.freeCash / i.accountSize * 100;
    final symbolCap = i.accountSize * i.maxSymbolPercent / 100;
    final budget = i.freeCash < symbolCap ? i.freeCash : symbolCap;

    final warnings = <String>[];
    for (final s in symbols.where((s) => s.overLimit)) {
      warnings.add(
        '${s.symbol} is ${s.percentOfAccount.toStringAsFixed(0)}% of your '
        'account, above the ${i.maxSymbolPercent.toStringAsFixed(0)}% limit.',
      );
    }
    if (freePercent < i.minCashReservePercent) {
      warnings.add(
        'Free cash is ${freePercent.toStringAsFixed(1)}% of your account, '
        'below the ${i.minCashReservePercent.toStringAsFixed(0)}% reserve.',
      );
    }
    final under = metrics.where((m) => m.underearning).length;
    if (under > 0) {
      warnings.add(
        '$under position${under == 1 ? '' : 's'} earned less than idle cash '
        'would have at ${i.benchmarkAnnualPercent.toStringAsFixed(1)}%.',
      );
    }

    return AllocationResult(
      totalDeployed: deployed,
      deployedPercent: deployed / i.accountSize * 100,
      freeCash: i.freeCash,
      freeCashPercent: freePercent,
      weightedAnnualizedReturnPercent: deployed > 0
          ? annualizedPremium / deployed * 100
          : null,
      totalPremium: premium,
      totalOpportunityCost: opportunity,
      holdings: metrics,
      symbols: symbols,
      capitalByStrategy: byStrategy,
      capitalFreedWithin: freed,
      newPositionBudget: budget,
      warnings: warnings,
    );
  }
}
