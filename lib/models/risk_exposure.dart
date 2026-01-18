class RiskExposure {
  final double totalRiskPercent;
  final bool assignmentExposure;
  final List<String> warnings;

  RiskExposure({
    required this.totalRiskPercent,
    required this.assignmentExposure,
    this.warnings = const [],
  });
}
