class BacktestResult {
  final List<double> equityCurve;
  final double maxDrawdown;
  final double totalReturn;
  final int cyclesCompleted;
  final List<String> notes;

  BacktestResult({
    required this.equityCurve,
    required this.maxDrawdown,
    required this.totalReturn,
    required this.cyclesCompleted,
    required this.notes,
  });
}
