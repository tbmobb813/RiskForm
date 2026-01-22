import 'package:riskform/services/mock_market_data_service.dart';
import 'analytics/strategy_recommendations_engine.dart';
import 'analytics/strategy_narrative_engine.dart';

/// Central default services used by UI factories and tests.
final MockMarketDataService defaultMarketDataService = MockMarketDataService();
const StrategyRecommendationsEngine defaultRecsEngine = StrategyRecommendationsEngine();
const StrategyNarrativeEngine defaultNarrativeEngine = StrategyNarrativeEngine();
