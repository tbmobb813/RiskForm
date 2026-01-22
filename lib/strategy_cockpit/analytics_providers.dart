import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics/strategy_recommendations_engine.dart';
import 'analytics/strategy_narrative_engine.dart';

final strategyRecommendationsEngineProvider = Provider<StrategyRecommendationsEngine>((ref) {
  return const StrategyRecommendationsEngine();
});

final strategyNarrativeEngineProvider = Provider<StrategyNarrativeEngine>((ref) {
  return const StrategyNarrativeEngine();
});
