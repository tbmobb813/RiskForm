import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_data_providers.dart';
import 'regime_aware_planner_hints_service.dart';
import '../engines/regime_providers.dart';

final regimeAwarePlannerHintsServiceProvider = Provider<RegimeAwarePlannerHintsService>((ref) {
  final market = ref.read(marketDataServiceProvider);
  final regime = ref.read(regimeEngineProvider);
  return RegimeAwarePlannerHintsService(market, regime);
});
