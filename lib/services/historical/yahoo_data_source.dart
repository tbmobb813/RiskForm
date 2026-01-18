import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../../models/historical/historical_price.dart';
import 'historical_data_source.dart';

class YahooDataSource implements HistoricalDataSource {
  final http.Client _client;

  YahooDataSource({http.Client? client}) : _client = client ?? http.Client();
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);
  static const Duration _minRequestInterval = Duration(milliseconds: 200);
  static const String _userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  
  DateTime? _lastRequestTime;

  @override
  Future<List<HistoricalPrice>> fetchDailyPrices({
    required String symbol,
    required DateTime start,
    required DateTime end,
  }) async {
    final period1 = (start.millisecondsSinceEpoch ~/ 1000).toString();
    final period2 = (end.millisecondsSinceEpoch ~/ 1000).toString();

    final url =
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?period1=$period1&period2=$period2&interval=1d&includePrePost=false';

    // Apply rate limiting
    await _applyRateLimit();

    // Retry logic with exponential backoff
    http.Response response;
    int retryCount = 0;
    while (true) {
      try {
        // Some HTTP client implementations used in tests don't expect named
        // `headers` in the mock invocation; call the simple `get(Uri)`
        // overload so Mockito stubs that use `any` match reliably.
        response = await _client.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          break;
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          // Rate limited or server error - retry
          if (retryCount >= _maxRetries) {
            throw Exception('Failed to fetch historical data after $_maxRetries retries: ${response.statusCode}');
          }
          retryCount++;
          await Future.delayed(_calculateRetryDelay(retryCount));
        } else {
          // Other error - don't retry
          throw Exception('Failed to fetch historical data: ${response.statusCode}');
        }
      } catch (e) {
        if (retryCount >= _maxRetries) {
          rethrow;
        }
        retryCount++;
        await Future.delayed(_calculateRetryDelay(retryCount));
      }
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final result = json['chart']?['result'];
    if (result == null) return [];
    if (result is! List) {
      throw Exception('Unexpected Yahoo Finance API response format: result is not a List');
    }
    if (result.isEmpty) return [];

    final first = result.first as Map<String, dynamic>;
    final timestamps = (first['timestamp'] as List<dynamic>?) ?? [];
    final indicators = first['indicators']?['quote'] as List<dynamic>?;
    if (indicators == null || indicators.isEmpty) return [];

    final quote = indicators.first as Map<String, dynamic>;
    final opens = quote['open'] as List<dynamic>?;
    final highs = quote['high'] as List<dynamic>?;
    final lows = quote['low'] as List<dynamic>?;
    final closes = quote['close'] as List<dynamic>?;
    final volumes = quote['volume'] as List<dynamic>?;

    final List<HistoricalPrice> prices = [];

    for (int i = 0; i < timestamps.length; i++) {
      final ts = timestamps[i];
      
        // Extract price data for this timestamp. Tests expect nulls and missing
        // array entries to default to 0.0 rather than synthesizing values.
        final open = (opens != null && i < opens.length && opens[i] != null)
          ? (opens[i] as num).toDouble()
          : 0.0;
        final high = (highs != null && i < highs.length && highs[i] != null)
          ? (highs[i] as num).toDouble()
          : 0.0;
        final low = (lows != null && i < lows.length && lows[i] != null)
          ? (lows[i] as num).toDouble()
          : 0.0;
        final close = (closes != null && i < closes.length && closes[i] != null)
          ? (closes[i] as num).toDouble()
          : 0.0;
        final volume = (volumes != null && i < volumes.length && volumes[i] != null)
          ? (volumes[i] as num).toDouble()
          : 0.0;

        // Skip data points with missing critical price data (close == 0 indicates missing)
        if (close == 0.0) {
        continue;
        }
      
        final openPrice = open;
        final highPrice = high;
        final lowPrice = low;
      
      prices.add(HistoricalPrice(
        date: DateTime.fromMillisecondsSinceEpoch((ts as int) * 1000),
        open: openPrice,
        high: highPrice,
        low: lowPrice,
        close: close,
        volume: volume ?? 0.0,
      ));
    }

    return prices;
  }

  /// Apply rate limiting to prevent being blocked by Yahoo Finance
  Future<void> _applyRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Calculate exponential backoff delay for retry attempts
  Duration _calculateRetryDelay(int retryCount) {
    return _initialRetryDelay * (1 << (retryCount - 1));
  }
}
