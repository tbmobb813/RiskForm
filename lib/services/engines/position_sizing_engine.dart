/// Pure-Dart position sizing for capital-efficient income strategies.
///
/// Supports cash-secured puts and credit spreads. All dollar figures are per
/// position (contract multiplier of 100 already applied).
library;

const int kContractMultiplier = 100;

enum SizingStrategy { csp, creditSpread }

enum SizingLimit { capital, risk }

class PositionSizingInput {
  final SizingStrategy strategy;

  /// CSP: the put strike. Credit spread: the short strike.
  final double strike;

  /// Credit spread only: distance between short and long strikes.
  final double spreadWidth;

  /// Premium received per share (net credit for spreads).
  final double premium;

  final double accountSize;
  final double buyingPower;

  /// Max % of account allowed to be tied up in this one position.
  final double maxCapitalPercent;

  /// Max % of account that may be lost if this position goes fully wrong.
  final double maxLossPercent;

  const PositionSizingInput({
    required this.strategy,
    required this.strike,
    this.spreadWidth = 0,
    required this.premium,
    required this.accountSize,
    required this.buyingPower,
    this.maxCapitalPercent = 30,
    this.maxLossPercent = 10,
  });
}

class PositionSizingResult {
  final double capitalPerContract;
  final double maxLossPerContract;
  final double premiumPerContract;

  /// Premium / capital, as a percent, for one cycle.
  final double returnOnCapitalPercent;

  final int maxContractsByCapital;
  final int maxContractsByRisk;
  final int recommendedContracts;
  final SizingLimit limitingFactor;

  final double totalCapital;
  final double totalPremium;
  final double totalMaxLoss;
  final double capitalPercentOfAccount;

  /// Smallest account that fits one contract under the capital % cap.
  final double minAccountForOneContract;

  final List<String> warnings;

  const PositionSizingResult({
    required this.capitalPerContract,
    required this.maxLossPerContract,
    required this.premiumPerContract,
    required this.returnOnCapitalPercent,
    required this.maxContractsByCapital,
    required this.maxContractsByRisk,
    required this.recommendedContracts,
    required this.limitingFactor,
    required this.totalCapital,
    required this.totalPremium,
    required this.totalMaxLoss,
    required this.capitalPercentOfAccount,
    required this.minAccountForOneContract,
    required this.warnings,
  });
}

class StrikeLadderRow {
  final double strike;
  final double premium;
  final double capitalPerContract;
  final double returnOnCapitalPercent;
  final bool affordable;

  const StrikeLadderRow({
    required this.strike,
    required this.premium,
    required this.capitalPerContract,
    required this.returnOnCapitalPercent,
    required this.affordable,
  });
}

class PositionSizingEngine {
  const PositionSizingEngine();

  /// Returns null when the inputs do not describe a valid position.
  PositionSizingResult? size(PositionSizingInput i) {
    if (!_isValid(i)) return null;

    final capital = _capitalPerContract(i);
    final maxLoss = _maxLossPerContract(i);
    final premium = i.premium * kContractMultiplier;

    final capitalBudget = _min(
      i.buyingPower,
      i.accountSize * i.maxCapitalPercent / 100,
    );
    final riskBudget = i.accountSize * i.maxLossPercent / 100;

    final byCapital = _floorDiv(capitalBudget, capital);
    final byRisk = _floorDiv(riskBudget, maxLoss);
    final recommended = byCapital < byRisk ? byCapital : byRisk;

    final limit = byCapital <= byRisk ? SizingLimit.capital : SizingLimit.risk;

    final totalCapital = capital * recommended;
    final minAccount = i.maxCapitalPercent <= 0
        ? double.infinity
        : capital / (i.maxCapitalPercent / 100);

    final warnings = <String>[];
    if (recommended == 0) {
      if (capital > i.buyingPower) {
        warnings.add(
          'One contract needs \$${_fmt(capital)} but buying power is '
          '\$${_fmt(i.buyingPower)}.',
        );
      } else if (byCapital == 0) {
        warnings.add(
          'One contract exceeds your ${_fmt(i.maxCapitalPercent)}% capital '
          'cap. You would need an account of about \$${_fmt(minAccount)}.',
        );
      } else {
        warnings.add(
          'One contract risks \$${_fmt(maxLoss)}, above your '
          '${_fmt(i.maxLossPercent)}% max loss '
          '(\$${_fmt(riskBudget)}).',
        );
      }
    }
    if (premium / capital * 100 < 1 && recommended > 0) {
      warnings.add('Premium is under 1% of capital; the return is thin.');
    }

    return PositionSizingResult(
      capitalPerContract: capital,
      maxLossPerContract: maxLoss,
      premiumPerContract: premium,
      returnOnCapitalPercent: premium / capital * 100,
      maxContractsByCapital: byCapital,
      maxContractsByRisk: byRisk,
      recommendedContracts: recommended,
      limitingFactor: limit,
      totalCapital: totalCapital,
      totalPremium: premium * recommended,
      totalMaxLoss: maxLoss * recommended,
      capitalPercentOfAccount: i.accountSize <= 0
          ? 0
          : totalCapital / i.accountSize * 100,
      minAccountForOneContract: minAccount,
      warnings: warnings,
    );
  }

  /// Capital needed and return on capital for each (strike, premium) pair,
  /// sorted by strike ascending. CSP only.
  List<StrikeLadderRow> cspLadder({
    required List<MapEntry<double, double>> strikesAndPremiums,
    required double buyingPower,
  }) {
    final rows = <StrikeLadderRow>[];
    for (final e in strikesAndPremiums) {
      if (e.key <= 0 || e.value < 0) continue;
      final capital = e.key * kContractMultiplier;
      rows.add(
        StrikeLadderRow(
          strike: e.key,
          premium: e.value,
          capitalPerContract: capital,
          returnOnCapitalPercent: e.value * kContractMultiplier / capital * 100,
          affordable: capital <= buyingPower,
        ),
      );
    }
    rows.sort((a, b) => a.strike.compareTo(b.strike));
    return rows;
  }

  bool _isValid(PositionSizingInput i) {
    if (i.strike <= 0 || i.premium < 0) return false;
    if (i.accountSize <= 0 || i.buyingPower < 0) return false;
    if (i.strategy == SizingStrategy.creditSpread) {
      if (i.spreadWidth <= 0 || i.premium >= i.spreadWidth) return false;
    } else if (i.premium >= i.strike) {
      return false;
    }
    return true;
  }

  // CSP collateral is the full strike; spreads collateralize width less credit.
  double _capitalPerContract(PositionSizingInput i) {
    switch (i.strategy) {
      case SizingStrategy.csp:
        return i.strike * kContractMultiplier;
      case SizingStrategy.creditSpread:
        return (i.spreadWidth - i.premium) * kContractMultiplier;
    }
  }

  // CSP worst case is assignment with the stock going to zero.
  double _maxLossPerContract(PositionSizingInput i) {
    switch (i.strategy) {
      case SizingStrategy.csp:
        return (i.strike - i.premium) * kContractMultiplier;
      case SizingStrategy.creditSpread:
        return (i.spreadWidth - i.premium) * kContractMultiplier;
    }
  }

  int _floorDiv(double budget, double unit) =>
      budget <= 0 ? 0 : (budget / unit).floor();

  double _min(double a, double b) => a < b ? a : b;

  String _fmt(double v) => v.isInfinite ? 'n/a' : v.toStringAsFixed(0);
}
