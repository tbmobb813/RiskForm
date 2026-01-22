import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SmallAccountSizer provides reusable position-sizing helpers for the
/// small-account flow. Methods are intentionally minimal and deterministic
/// so UI/logic can call them and present options to users.
class SmallAccountSizer {
  const SmallAccountSizer();

  /// Returns the capital required for a single contract (per-contract cost).
  double requiredCapitalPerContract(double costPerContract) => costPerContract;

  /// Recommend maximum whole contracts based on a percent-of-account risk rule.
  /// Example: riskPct = 0.05 -> risk 5% of account.
  int recommendedContractsByRisk({
    required double accountBalance,
    required double costPerContract,
    double riskPct = 0.05,
  }) {
    if (accountBalance <= 0 || costPerContract <= 0) return 0;
    final maxRiskCapital = accountBalance * riskPct;
    return (maxRiskCapital / costPerContract).floor();
  }

  /// Recommend maximum whole contracts based on an allocation percent of the
  /// account (capital deployment rather than risk percent).
  int recommendedContractsByAllocation({
    required double accountBalance,
    required double costPerContract,
    required double allocationPct,
  }) {
    if (accountBalance <= 0 || costPerContract <= 0 || allocationPct <= 0) return 0;
    final allocCapital = accountBalance * allocationPct;
    return (allocCapital / costPerContract).floor();
  }

  /// Returns a small set of recommended sizing options useful for UI.
  Map<String, dynamic> sizeRecommendations({
    required double accountBalance,
    required double costPerContract,
    List<double> allocationPercents = const [0.05, 0.10],
  }) {
    final Map<String, dynamic> out = {};
    out['byRisk_5pct'] = recommendedContractsByRisk(accountBalance: accountBalance, costPerContract: costPerContract, riskPct: 0.05);
    out['byRisk_10pct'] = recommendedContractsByRisk(accountBalance: accountBalance, costPerContract: costPerContract, riskPct: 0.10);

    final allocs = <String, int>{};
    for (final p in allocationPercents) {
      allocs['${(p * 100).toInt()}%'] = recommendedContractsByAllocation(accountBalance: accountBalance, costPerContract: costPerContract, allocationPct: p);
    }
    out['allocations'] = allocs;
    out['capitalPerContract'] = requiredCapitalPerContract(costPerContract);
    return out;
  }

  /// Capital required for a proposed number of contracts.
  double capitalRequired(int contracts, double costPerContract) {
    if (contracts <= 0 || costPerContract <= 0) return 0.0;
    return contracts * costPerContract;
  }
}

final smallAccountSizerProvider = Provider<SmallAccountSizer>((ref) => const SmallAccountSizer());
