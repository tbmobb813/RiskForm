import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'regime_engine.dart';
import '../services/market_data_providers.dart';

/// Provides a `RegimeEngine` wired to the app's `MarketDataService`.
final regimeEngineProvider = Provider<RegimeEngine>((ref) {
  final market = ref.read(marketDataServiceProvider);
  return LiveRegimeEngine(market);
});

/// Helper override to inject test or alternative implementations.
Provider<RegimeEngine> regimeEngineOverride(RegimeEngine engine) =>
    Provider<RegimeEngine>((_) => engine);
