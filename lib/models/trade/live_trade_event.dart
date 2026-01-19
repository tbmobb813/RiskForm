enum LiveTradeType {
  openCsp,
  closeCsp,
  openCc,
  closeCc,
  assignment,
  calledAway,
  shareBuy,
  shareSell,
}

class LiveTradeEvent {
  final String id;
  final DateTime timestamp;
  final String symbol;
  final LiveTradeType type;
  final double price;
  final int quantity;
  final double? strike;
  final DateTime? expiry;

  LiveTradeEvent({
    required this.id,
    required this.timestamp,
    required this.symbol,
    required this.type,
    required this.price,
    required this.quantity,
    this.strike,
    this.expiry,
  });
}
