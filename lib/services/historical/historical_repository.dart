import '../../models/historical/historical_price.dart';
import 'historical_data_source.dart';
import 'historical_cache.dart';

class HistoricalRepository {
  final HistoricalDataSource source;
  final HistoricalCache cache;

  HistoricalRepository({
    required this.source,
    required this.cache,
  });

  Future<List<HistoricalPrice>> getDailyPrices({
    required String symbol,
    required DateTime start,
    required DateTime end,
  }) async {
    // 1. Try cache
    final cached = cache.load(symbol: symbol, start: start, end: end);
    if (cached != null) return cached;

    // 2. Fetch from API
    final prices = await source.fetchDailyPrices(
      symbol: symbol,
      start: start,
      end: end,
    );

    // 3. Save to cache
    await cache.save(symbol: symbol, start: start, end: end, prices: prices);

    return prices;
  }
}
