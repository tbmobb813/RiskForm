import 'package:flutter_application_2/services/historical/historical_data_source.dart';
import 'package:flutter_application_2/models/historical/historical_price.dart';

/// Fake implementation of HistoricalDataSource for testing
class FakeHistoricalDataSource implements HistoricalDataSource {
  List<HistoricalPrice>? mockResponse;
  Exception? mockError;
  int fetchCallCount = 0;

  @override
  Future<List<HistoricalPrice>> fetchDailyPrices({
    required String symbol,
    required DateTime start,
    required DateTime end,
  }) async {
    fetchCallCount++;
    
    if (mockError != null) {
      throw mockError!;
    }
    
    return mockResponse ?? [];
  }
}
