class ScannerFilters {
  final double maxPremium;
  final int minDte;
  final int maxDte;
  final double maxBidAskSpread;
  final int minOpenInterest;
  final double? minDelta;
  final double? maxDelta;

  const ScannerFilters({
    required this.maxPremium,
    required this.minDte,
    required this.maxDte,
    required this.maxBidAskSpread,
    required this.minOpenInterest,
    this.minDelta,
    this.maxDelta,
  });
}
