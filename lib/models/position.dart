enum PositionType { csp, coveredCall, shares }
class Position {
  final PositionType type;
  final String symbol;
  final String strategy;
  final int quantity;
  final bool isOpen;
  final DateTime expiration;
  final List<String> riskFlags;

  Position({
    required this.type,
    required this.symbol,
    required this.strategy,
    required this.quantity,
    required this.expiration,
    required this.isOpen,
    this.riskFlags = const [],
  });

  String get expirationDateString =>
      "${expiration.month}/${expiration.day}/${expiration.year}";

  int get dte =>
      expiration.difference(DateTime.now()).inDays.clamp(0, 999);
}