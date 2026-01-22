import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_data_service.dart';
import 'mock_market_data_service.dart';

/// Provider for the MarketDataService used across the app.
///
/// Default implementation is `MockMarketDataService` for deterministic local
/// behavior. Swap with a live implementation in app startup or tests.
final marketDataServiceProvider = Provider<MarketDataService>((ref) {
  return MockMarketDataService();
});

/// Helper to override provider with a concrete instance in tests or app wiring.
Provider<MarketDataService> marketDataServiceOverride(MarketDataService svc) =>
    Provider<MarketDataService>((_) => svc);
