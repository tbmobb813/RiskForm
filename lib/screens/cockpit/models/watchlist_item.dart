/// Represents a ticker in the watchlist with optional live market data
class WatchlistItem {
  final String ticker;
  final double? price; // null if no live data
  final double? ivPercentile; // null if no live data
  final double? changePercent; // null if no live data
  final bool hasLiveData;
  final DateTime? lastUpdated;

  const WatchlistItem({
    required this.ticker,
    this.price,
    this.ivPercentile,
    this.changePercent,
    this.hasLiveData = false,
    this.lastUpdated,
  });

  /// Create a watchlist item without live data (Phase 1)
  factory WatchlistItem.placeholder(String ticker) {
    return WatchlistItem(
      ticker: ticker,
      hasLiveData: false,
    );
  }

  /// Create a watchlist item with live data (Phase 2)
  factory WatchlistItem.withLiveData({
    required String ticker,
    required double price,
    required double ivPercentile,
    required double changePercent,
  }) {
    return WatchlistItem(
      ticker: ticker,
      price: price,
      ivPercentile: ivPercentile,
      changePercent: changePercent,
      hasLiveData: true,
      lastUpdated: DateTime.now(),
    );
  }

  String get priceDisplay => hasLiveData && price != null ? '\$${price!.toStringAsFixed(2)}' : 'N/A';
  String get ivDisplay => hasLiveData && ivPercentile != null ? '${ivPercentile!.toStringAsFixed(0)}%' : 'N/A';
  String get changeDisplay {
    if (!hasLiveData || changePercent == null) return '—';
    final sign = changePercent! >= 0 ? '+' : '';
    return '$sign${changePercent!.toStringAsFixed(2)}%';
  }

  bool get isPositive => changePercent != null && changePercent! > 0;
  bool get isNegative => changePercent != null && changePercent! < 0;

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'price': price,
        'ivPercentile': ivPercentile,
        'changePercent': changePercent,
        'hasLiveData': hasLiveData,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      ticker: json['ticker'] as String,
      price: json['price'] as double?,
      ivPercentile: json['ivPercentile'] as double?,
      changePercent: json['changePercent'] as double?,
      hasLiveData: json['hasLiveData'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : null,
    );
  }
}
