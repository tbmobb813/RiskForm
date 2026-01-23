/// Represents a stock quote with price and volume data
class Quote {
  final String ticker;
  final double price;
  final double change;
  final double changePercent;
  final double open;
  final double high;
  final double low;
  final double volume;
  final DateTime timestamp;
  final bool isDelayed;

  const Quote({
    required this.ticker,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.timestamp,
    this.isDelayed = false,
  });

  /// Create from Tradier API response
  factory Quote.fromTradierJson(Map<String, dynamic> json) {
    final last = (json['last'] as num?)?.toDouble() ?? 0.0;
    final open = (json['open'] as num?)?.toDouble() ?? last;

    return Quote(
      ticker: json['symbol'] as String? ?? '',
      price: last,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['change_percentage'] as num?)?.toDouble() ?? 0.0,
      open: open,
      high: (json['high'] as num?)?.toDouble() ?? last,
      low: (json['low'] as num?)?.toDouble() ?? last,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
      isDelayed: true, // Tradier sandbox is delayed
    );
  }

  /// Create from Polygon.io API response
  factory Quote.fromPolygonJson(Map<String, dynamic> json) {
    final close = (json['c'] as num?)?.toDouble() ?? 0.0;
    final open = (json['o'] as num?)?.toDouble() ?? close;
    final change = close - open;
    final changePercent = open > 0 ? (change / open * 100) : 0.0;

    return Quote(
      ticker: json['T'] as String? ?? '',
      price: close,
      change: change,
      changePercent: changePercent,
      open: open,
      high: (json['h'] as num?)?.toDouble() ?? close,
      low: (json['l'] as num?)?.toDouble() ?? close,
      volume: (json['v'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['t'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['t'] as int)
          : DateTime.now(),
      isDelayed: false,
    );
  }

  /// Create a placeholder quote (for when data unavailable)
  factory Quote.placeholder(String ticker) {
    return Quote(
      ticker: ticker,
      price: 0.0,
      change: 0.0,
      changePercent: 0.0,
      open: 0.0,
      high: 0.0,
      low: 0.0,
      volume: 0.0,
      timestamp: DateTime.now(),
      isDelayed: true,
    );
  }

  @override
  String toString() {
    return 'Quote($ticker: \$$price ${change >= 0 ? '+' : ''}$changePercent%)';
  }
}
