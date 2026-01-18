class BacktestConfig {
  final double startingCapital;
  final int maxCycles;
  final List<double> pricePath;
  final String strategyId;
  final String? label;

  // Historical parameters
  final String symbol;
  final DateTime startDate;
  final DateTime endDate;

  BacktestConfig({
    required this.startingCapital,
    required this.maxCycles,
    required this.pricePath,
    required this.strategyId,
    this.label,
    required this.symbol,
    required this.startDate,
    required this.endDate,
  });

  BacktestConfig copyWith({
    double? startingCapital,
    int? maxCycles,
    List<double>? pricePath,
    String? strategyId,
    String? label,
    String? symbol,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BacktestConfig(
      startingCapital: startingCapital ?? this.startingCapital,
      maxCycles: maxCycles ?? this.maxCycles,
      pricePath: pricePath ?? this.pricePath,
      strategyId: strategyId ?? this.strategyId,
      label: label ?? this.label,
      symbol: symbol ?? this.symbol,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
