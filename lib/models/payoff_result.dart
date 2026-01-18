class PayoffResult {
  final double maxGain;
  final double maxLoss;
  final double breakeven;
  final double capitalRequired;

  PayoffResult({
    required this.maxGain,
    required this.maxLoss,
    required this.breakeven,
    required this.capitalRequired,
  });

  String get maxGainString => "\$${maxGain.toStringAsFixed(2)}";
  String get maxLossString => "\$${maxLoss.toStringAsFixed(2)}";
  String get breakevenString => "\$${breakeven.toStringAsFixed(2)}";
  String get capitalRequiredString => "\$${capitalRequired.toStringAsFixed(2)}";
}