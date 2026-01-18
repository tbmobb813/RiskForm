class Position {
  final String symbol;
  final String strategy;
  final DateTime expiration;
  final List<String> riskFlags;

  Position({
    required this.symbol,
    required this.strategy,
    required this.expiration,
    this.riskFlags = const [],
  });

  String get expirationDateString =>
      "${expiration.month}/${expiration.day}/${expiration.year}";

  int get dte =>
      expiration.difference(DateTime.now()).inDays.clamp(0, 999);
}