import '../../models/historical/historical_price.dart';

abstract class HistoricalDataSource {
  Future<List<HistoricalPrice>> fetchDailyPrices({
    required String symbol,
    required DateTime start,
    required DateTime end,
  });
}
