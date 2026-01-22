import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/market_data_providers.dart';
import '../engines/regime_providers.dart';
import 'analytics_providers.dart';
import 'live_sync_manager.dart';
import '../services/regime_aware_planner_hints_providers.dart';

final liveSyncManagerProvider = Provider<LiveSyncManager>((ref) {
  final market = ref.read(marketDataServiceProvider);
  final regime = ref.read(regimeEngineProvider);
  final recs = ref.read(strategyRecommendationsEngineProvider);
  final hints = ref.read(regimeAwarePlannerHintsServiceProvider);
  final narr = ref.read(strategyNarrativeEngineProvider);

  return LiveSyncManager(
    market: market,
    regimeEngine: regime,
    recsEngine: recs,
    hintsService: hints,
    narrativeEngine: narr,
  );
});
