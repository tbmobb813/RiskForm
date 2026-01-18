class BacktestConfig {
  final double startingCapital;
  final int maxCycles;
  final List<double> pricePath;
  final String strategyId;

  BacktestConfig({
    required this.startingCapital,
    required this.maxCycles,
    required this.pricePath,
    required this.strategyId,
  });
}
