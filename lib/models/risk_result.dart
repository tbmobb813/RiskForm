class RiskResult {
  final double riskPercentOfAccount;
  final bool assignmentExposure;
  final double capitalLocked;
  final List<String> warnings;

  RiskResult({
    required this.riskPercentOfAccount,
    required this.assignmentExposure,
    required this.capitalLocked,
    required this.warnings,
  });
}