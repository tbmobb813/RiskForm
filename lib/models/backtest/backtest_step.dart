class BacktestStep {
  final double price;
  final double equity;
  final String action;
  final String reason;

  BacktestStep({
    required this.price,
    required this.equity,
    required this.action,
    required this.reason,
  });
}
