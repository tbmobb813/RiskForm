import 'package:hive/hive.dart';
import '../../models/historical/historical_price.dart';

class HistoricalCache {
  final Box box;

  HistoricalCache(this.box);

  String _key(String symbol, DateTime start, DateTime end) =>
      "${symbol.toUpperCase()}-${start.toIso8601String()}-${end.toIso8601String()}";

  Future<void> save({
    required String symbol,
    required DateTime start,
    required DateTime end,
    required List<HistoricalPrice> prices,
  }) async {
    final key = _key(symbol, start, end);
    final data = prices
        .map((p) => {
              'date': p.date.toIso8601String(),
              'open': p.open,
              'high': p.high,
              'low': p.low,
              'close': p.close,
              'volume': p.volume,
            })
        .toList();

    await box.put(key, data);
  }

  List<HistoricalPrice>? load({
    required String symbol,
    required DateTime start,
    required DateTime end,
  }) {
    final key = _key(symbol, start, end);
    final data = box.get(key);
    if (data == null) return null;

    return (data as List)
        .map((m) => HistoricalPrice(
              date: DateTime.parse(m['date'] as String),
              open: (m['open'] as num).toDouble(),
              high: (m['high'] as num).toDouble(),
              low: (m['low'] as num).toDouble(),
              close: (m['close'] as num).toDouble(),
              volume: (m['volume'] as num).toDouble(),
            ))
        .toList();
  }
}
