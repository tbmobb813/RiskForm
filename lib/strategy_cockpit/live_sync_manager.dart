
import '../../services/market_data_service.dart';
import '../../services/market_data_models.dart';
import '../../engines/regime_engine.dart';
import 'analytics/strategy_recommendations_engine.dart';
import '../../services/regime_aware_planner_hints_service.dart';
import 'analytics/regime_aware_planner_hints.dart' as planner_hints;
import 'analytics/strategy_narrative_engine.dart';
// cleaned imports: no Riverpod usage here and avoid duplicate imports

/// Result model returned by LiveSyncManager.refresh
class LiveSyncResult {
  final MarketRegimeSnapshot regime;
  final StrategyRecommendationsBundle recommendations;
  final dynamic hints;
  final StrategyNarrative narrative;

  LiveSyncResult({
    required this.regime,
    required this.recommendations,
    required this.hints,
    required this.narrative,
  });
}

/// Orchestrates a deterministic, ordered refresh of live market intelligence
class LiveSyncManager {
  final MarketDataService market;
  final RegimeEngine regimeEngine;
  final StrategyRecommendationsEngine recsEngine;
  final RegimeAwarePlannerHintsService hintsService;
  final StrategyNarrativeEngine narrativeEngine;

  const LiveSyncManager({
    required this.market,
    required this.regimeEngine,
    required this.recsEngine,
    required this.hintsService,
    required this.narrativeEngine,
  });

  Future<LiveSyncResult> refresh(String symbol, StrategyContext ctx, {planner_hints.PlannerState? plannerState}) async {
    final vol = await market.getVolatility(symbol);
    final liq = await market.getLiquidity(symbol);

    final reg = await regimeEngine.getRegime(symbol);

    final recBundle = await recsEngine.generate(
      context: ctx,
      regime: reg,
      vol: vol,
      liq: liq,
    );
    final hintBundle = await hintsService.generateHints(
      plannerState ?? planner_hints.PlannerState(dte: 30, delta: 0.2, width: 20.0, size: 1, type: ctx.currentRegime),
      symbol: symbol,
      contextOverrides: ctx,
    );

    final story = narrativeEngine.generate(
      context: ctx,
      recs: recBundle,
      regime: reg,
      vol: vol,
      liq: liq,
    );

    return LiveSyncResult(
      regime: reg,
      recommendations: recBundle,
      hints: hintBundle,
      narrative: story,
    );
  }
}
