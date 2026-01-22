class OptionContract {
  final String id;
  final double strike;
  final double premium;
  final DateTime expiry;
  final String type; // 'call' | 'put'

  OptionContract({
    required this.id,
    required this.strike,
    required this.premium,
    required this.expiry,
    required this.type,
  });
}
