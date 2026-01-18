import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../services/historical/yahoo_data_source.dart';
import '../services/historical/historical_cache.dart';
import '../services/historical/historical_repository.dart';

final historicalDataSourceProvider = Provider((ref) => YahooDataSource());

final historicalCacheProvider = Provider((ref) {
  final box = Hive.box('historical_cache');
  return HistoricalCache(box);
});

final historicalRepositoryProvider = Provider((ref) {
  return HistoricalRepository(
    source: ref.read(historicalDataSourceProvider),
    cache: ref.read(historicalCacheProvider),
  );
});
