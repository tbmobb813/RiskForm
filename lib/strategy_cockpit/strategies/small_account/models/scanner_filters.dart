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

  ScannerFilters copyWith({
    double? maxPremium,
    int? minDte,
    int? maxDte,
    double? maxBidAskSpread,
    int? minOpenInterest,
    double? minDelta,
    double? maxDelta,
  }) {
    return ScannerFilters(
      maxPremium: maxPremium ?? this.maxPremium,
      minDte: minDte ?? this.minDte,
      maxDte: maxDte ?? this.maxDte,
      maxBidAskSpread: maxBidAskSpread ?? this.maxBidAskSpread,
      minOpenInterest: minOpenInterest ?? this.minOpenInterest,
      minDelta: minDelta ?? this.minDelta,
      maxDelta: maxDelta ?? this.maxDelta,
    );
  }
}
