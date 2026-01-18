class RiskProfile {
  final String id;
  final double maxRiskPercent;

  RiskProfile({required this.id, required this.maxRiskPercent});

  /// Backwards-compatible getter used by older controller code.
  double get maxRiskPerTradePercent => maxRiskPercent;
}
