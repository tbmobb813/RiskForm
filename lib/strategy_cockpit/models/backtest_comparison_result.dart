class BacktestComparisonResult {
  final List<Map<String, dynamic>> runs; // raw runs with metrics
  final Map<String, dynamic>? bestConfig;
  final Map<String, dynamic>? worstConfig;
  final Map<String, String> regimeWeaknesses; // regime -> note
  final String summaryNote;

  const BacktestComparisonResult({
    required this.runs,
    required this.bestConfig,
    required this.worstConfig,
    required this.regimeWeaknesses,
    required this.summaryNote,
  });
}
