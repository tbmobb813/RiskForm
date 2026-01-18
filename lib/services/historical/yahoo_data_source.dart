import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/historical/historical_price.dart';
import 'historical_data_source.dart';

class YahooDataSource implements HistoricalDataSource {
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

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch historical data: ${response.statusCode}');
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
      
      // Extract price data for this timestamp
      final open = (opens != null && i < opens.length && opens[i] != null) ? (opens[i] as num).toDouble() : null;
      final high = (highs != null && i < highs.length && highs[i] != null) ? (highs[i] as num).toDouble() : null;
      final low = (lows != null && i < lows.length && lows[i] != null) ? (lows[i] as num).toDouble() : null;
      final close = (closes != null && i < closes.length && closes[i] != null) ? (closes[i] as num).toDouble() : null;
      final volume = (volumes != null && i < volumes.length && volumes[i] != null) ? (volumes[i] as num).toDouble() : null;
      
      // Skip data points with missing critical price data (close is essential for backtesting)
      if (close == null) {
        continue;
      }
      
      // Use close price as fallback for missing OHLC values to maintain valid price relationships
      prices.add(HistoricalPrice(
        date: DateTime.fromMillisecondsSinceEpoch((ts as int) * 1000),
        open: open ?? close,
        high: high ?? close,
        low: low ?? close,
        close: close,
        volume: volume ?? 0.0,
      ));
    }

    return prices;
  }
}
