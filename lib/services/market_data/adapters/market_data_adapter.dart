import '../models/quote.dart';
import '../models/options_chain.dart';

/// Abstract interface for market data providers
///
/// Implementations: TradierAdapter, PolygonAdapter, YahooAdapter
abstract class MarketDataAdapter {
  /// Whether this adapter supports batch quote requests
  bool get supportsBatch;

  /// Whether this adapter supports WebSocket streaming
  bool get supportsWebSocket;

  /// Whether this adapter provides real-time data (vs delayed)
  bool get isRealTime;

  /// Fetch a single quote
  Future<Quote> fetchQuote(String ticker);

  /// Fetch multiple quotes in a single request (if supported)
  Future<List<Quote>> fetchQuotesBatch(List<String> tickers);

  /// Fetch full options chain for a ticker
  Future<OptionsChain> fetchOptionsChain(String ticker, {DateTime? expiration});

  /// Fetch historical prices for technical analysis
  Future<List<HistoricalPrice>> fetchHistoricalPrices(
    String ticker, {
    required int days,
  });

  /// Calculate current implied volatility for the underlying
  Future<double> fetchCurrentIV(String ticker);

  /// Fetch historical IV data for percentile calculation
  Future<List<double>> fetchHistoricalIV(
    String ticker, {
    required int days,
  });

  /// Subscribe to real-time quote updates (WebSocket)
  Stream<Quote>? subscribeToQuote(String ticker);

  /// Close any open connections
  Future<void> close();
}

/// Historical price data point
class HistoricalPrice {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const HistoricalPrice({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// True range for ATR calculation
  double get trueRange => high - low;
}

/// Exception thrown when market data operations fail
class MarketDataException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  MarketDataException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    return 'MarketDataException: $message'
        '${statusCode != null ? ' (HTTP $statusCode)' : ''}'
        '${originalError != null ? '\nCaused by: $originalError' : ''}';
  }
}
