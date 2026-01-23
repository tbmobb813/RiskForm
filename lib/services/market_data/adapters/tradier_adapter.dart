import 'dart:convert';
import 'package:http/http.dart' as http;
import 'market_data_adapter.dart';
import '../models/quote.dart';
import '../models/options_chain.dart';

/// Tradier API adapter for market data
///
/// Free sandbox: Unlimited requests, 15-min delayed data
/// Real-time: Free with Tradier brokerage account OR $10/month
///
/// Docs: https://documentation.tradier.com/brokerage-api/markets
class TradierAdapter implements MarketDataAdapter {
  final String apiKey;
  final bool useSandbox;
  final http.Client _client;

  TradierAdapter({
    required this.apiKey,
    this.useSandbox = true,
  }) : _client = http.Client();

  String get _baseUrl => useSandbox
      ? 'https://sandbox.tradier.com/v1'
      : 'https://api.tradier.com/v1';

  @override
  bool get supportsBatch => true;

  @override
  bool get supportsWebSocket => true; // Tradier has WebSocket API

  @override
  bool get isRealTime => !useSandbox;

  @override
  Future<Quote> fetchQuote(String ticker) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/markets/quotes?symbols=$ticker'),
        headers: _headers,
      );

      _checkResponse(response);

      final data = json.decode(response.body);
      final quote = data['quotes']['quote'];

      return Quote.fromTradierJson(quote is List ? quote.first : quote);
    } catch (e) {
      throw MarketDataException(
        'Failed to fetch quote for $ticker',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Quote>> fetchQuotesBatch(List<String> tickers) async {
    if (tickers.isEmpty) return [];

    try {
      final symbols = tickers.join(',');
      final response = await _client.get(
        Uri.parse('$_baseUrl/markets/quotes?symbols=$symbols'),
        headers: _headers,
      );

      _checkResponse(response);

      final data = json.decode(response.body);
      final quotesData = data['quotes']['quote'];

      if (quotesData == null) {
        return tickers.map((t) => Quote.placeholder(t)).toList();
      }

      // Handle single vs multiple quotes
      if (quotesData is List) {
        return quotesData.map((q) => Quote.fromTradierJson(q)).toList();
      } else {
        return [Quote.fromTradierJson(quotesData)];
      }
    } catch (e) {
      throw MarketDataException(
        'Failed to fetch quotes for ${tickers.join(', ')}',
        originalError: e,
      );
    }
  }

  @override
  Future<OptionsChain> fetchOptionsChain(
    String ticker, {
    DateTime? expiration,
  }) async {
    try {
      final uri = expiration != null
          ? Uri.parse('$_baseUrl/markets/options/chains?symbol=$ticker&expiration=${_formatDate(expiration)}&greeks=true')
          : Uri.parse('$_baseUrl/markets/options/chains?symbol=$ticker&greeks=true');

      final response = await _client.get(uri, headers: _headers);

      _checkResponse(response);

      final data = json.decode(response.body);
      return OptionsChain.fromTradierJson(ticker, data);
    } catch (e) {
      throw MarketDataException(
        'Failed to fetch options chain for $ticker',
        originalError: e,
      );
    }
  }

  @override
  Future<List<HistoricalPrice>> fetchHistoricalPrices(
    String ticker, {
    required int days,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final response = await _client.get(
        Uri.parse(
          '$_baseUrl/markets/history?symbol=$ticker'
          '&start=${_formatDate(startDate)}'
          '&end=${_formatDate(endDate)}',
        ),
        headers: _headers,
      );

      _checkResponse(response);

      final data = json.decode(response.body);
      final history = data['history']?['day'];

      if (history == null) return [];

      final historyList = history is List ? history : [history];

      return historyList.map((h) {
        return HistoricalPrice(
          date: DateTime.parse(h['date']),
          open: (h['open'] as num).toDouble(),
          high: (h['high'] as num).toDouble(),
          low: (h['low'] as num).toDouble(),
          close: (h['close'] as num).toDouble(),
          volume: (h['volume'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      throw MarketDataException(
        'Failed to fetch historical prices for $ticker',
        originalError: e,
      );
    }
  }

  @override
  Future<double> fetchCurrentIV(String ticker) async {
    // Fetch ATM options and average their IV
    try {
      final quote = await fetchQuote(ticker);
      final chain = await fetchOptionsChain(ticker);

      if (chain.calls.isEmpty) return 0.0;

      // Find ATM options (strike closest to current price)
      final atmCalls = chain.getContractsNearStrike(quote.price, delta: 2.0);

      if (atmCalls.isEmpty) return 0.0;

      // Average IV of ATM calls
      final ivSum = atmCalls
          .where((c) => c.greeks != null)
          .map((c) => c.greeks!.iv)
          .fold(0.0, (sum, iv) => sum + iv);

      final count = atmCalls.where((c) => c.greeks != null).length;

      return count > 0 ? ivSum / count : 0.0;
    } catch (e) {
      return 0.0; // Fail gracefully
    }
  }

  @override
  Future<List<double>> fetchHistoricalIV(
    String ticker, {
    required int days,
  }) async {
    // Tradier doesn't provide historical IV directly
    // Would need to calculate from historical options data
    // For MVP, return empty list
    return [];
  }

  @override
  Stream<Quote>? subscribeToQuote(String ticker) {
    // Tradier WebSocket implementation
    // For MVP, return null (polling is sufficient)
    return null;
  }

  @override
  Future<void> close() async {
    _client.close();
  }

  // Helper methods

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      };

  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw MarketDataException(
        'API request failed',
        statusCode: response.statusCode,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
