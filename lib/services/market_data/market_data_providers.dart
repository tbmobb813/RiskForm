import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'market_data_service.dart';

/// Provider for market data service
///
/// Returns null if no API key configured (graceful degradation)
final marketDataServiceProvider = Provider<MarketDataService?>((ref) {
  // Read configuration from environment or settings
  // For now, return null (Phase 1 - no live data)

  // TODO: Uncomment when ready to enable live data
  // final apiKey = dotenv.env['TRADIER_API_KEY'];
  // final useSandbox = dotenv.env['TRADIER_USE_SANDBOX'] == 'true';
  //
  // if (apiKey == null || apiKey.isEmpty) {
  //   return null; // Gracefully degrade to placeholder data
  // }
  //
  // return MarketDataService(
  //   provider: MarketDataProvider.tradier,
  //   apiKey: apiKey,
  //   useSandbox: useSandbox,
  //   rateLimitPerMinute: 60,
  // );

  return null; // Disabled for Phase 1
});

/// Provider for market data availability
final hasMarketDataProvider = Provider<bool>((ref) {
  return ref.watch(marketDataServiceProvider) != null;
});

/// Provider for real-time data availability
final hasRealTimeDataProvider = Provider<bool>((ref) {
  final service = ref.watch(marketDataServiceProvider);
  return service?.isRealTime ?? false;
});
