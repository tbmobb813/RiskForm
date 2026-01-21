import 'package:flutter/material.dart';

import '../services/market_data_service.dart';
import '../engines/regime_engine.dart';
import '../strategy_cockpit/analytics/regime_aware_planner_hints.dart' as planner_hints;
import '../strategy_cockpit/analytics/strategy_recommendations_engine.dart' as recs;
import '../services/market_data_models.dart';

/// Service that composes live market/regime context and the existing
/// pure `generateHints` function to produce `PlannerHintBundle` that is
/// regime-aware and suitable for the Planner UI.
class RegimeAwarePlannerHintsService {
  final MarketDataService marketData;
  final RegimeEngine regimeEngine;

  RegimeAwarePlannerHintsService(this.marketData, this.regimeEngine);

  /// Generate hints for the given planner `state` and optional `symbol`.
  ///
  /// This method is best-effort: if live data fetch fails it falls back to
  /// defaults and still returns a deterministic hints bundle.
  Future<planner_hints.PlannerHintBundle> generateHints(planner_hints.PlannerState state, {String? symbol, recs.StrategyContext? contextOverrides}) async {
    try {
      // Fetch live snapshots when symbol provided
      MarketPriceSnapshot? price;
      MarketVolatilitySnapshot? vol;
      MarketLiquiditySnapshot? liq;
      MarketRegimeSnapshot? regime;

      if (symbol != null) {
        price = await marketData.getPrice(symbol);
        vol = await marketData.getVolatility(symbol);
        liq = await marketData.getLiquidity(symbol);
        try {
          regime = await regimeEngine.getRegime(symbol);
        } catch (_) {
          regime = null;
        }
      }

      // Build a StrategyContext by merging live info with provided overrides.
      final constraints = contextOverrides?.constraints ?? recs.Constraints(maxRisk: 100, maxPositions: 5);
      final healthScore = contextOverrides?.healthScore ?? 50;
      final pnlTrend = contextOverrides?.pnlTrend ?? const <double>[];
      final disciplineTrend = contextOverrides?.disciplineTrend ?? const <int>[];
      final recentCycles = contextOverrides?.recentCycles ?? const <recs.CycleSummary>[];
      final backtestComparison = contextOverrides?.backtestComparison;
      final drawdown = contextOverrides?.drawdown ?? 0.0;

      final currentRegime = regime?.trend ?? (contextOverrides?.currentRegime ?? 'sideways');

      final ctx = recs.StrategyContext(
        healthScore: healthScore,
        pnlTrend: pnlTrend,
        disciplineTrend: disciplineTrend,
        recentCycles: recentCycles,
        constraints: constraints,
        currentRegime: currentRegime,
        drawdown: drawdown,
        backtestComparison: backtestComparison,
      );

      // Call the pure hint generator with our assembled context
      return planner_hints.generateHints(state, ctx);
    } catch (e) {
      // On any unexpected failure, return a safe default bundle
      final defaultCtx = recs.StrategyContext(
        healthScore: 50,
        pnlTrend: const <double>[],
        disciplineTrend: const <int>[],
        recentCycles: const <recs.CycleSummary>[],
        constraints: recs.Constraints(maxRisk: 100, maxPositions: 5),
        currentRegime: 'sideways',
        drawdown: 0.0,
        backtestComparison: null,
      );
      return planner_hints.generateHints(state, defaultCtx);
    }
  }
}
