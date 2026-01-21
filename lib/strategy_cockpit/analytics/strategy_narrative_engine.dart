import 'strategy_recommendations_engine.dart';
import 'package:riskform/services/market_data_models.dart';

/// Live-aware Strategy Narrative Engine (Phase 6.5)
class StrategyNarrativeEngine {
  const StrategyNarrativeEngine();

  StrategyNarrative generate({
    required StrategyContext context,
    required StrategyRecommendationsBundle recs,
    required MarketRegimeSnapshot regime,
    required MarketVolatilitySnapshot vol,
    required MarketLiquiditySnapshot liq,
  }) {
    // Base narrative from existing pure generator
    final base = generateNarrative(context, recsBundle: recs);

    // Build live regime phrase
    final trend = regime.trend.toLowerCase();
    final volLabel = regime.volatility.toLowerCase();
    final liqLabel = regime.liquidity.toLowerCase();
    final regimePhrase = '$volLabel-volatility $trend with $liqLabel liquidity';

    // Enrich summary: prepend a sentence about live regime
    final liveSummary = 'Current conditions: $regimePhrase. ${base.summary}';

    // Live bullets
    final liveBullets = <String>[];
    liveBullets.add('IV Rank: ${vol.ivRank.toStringAsFixed(0)} (IV Percentile: ${ (vol.ivPercentile * 100).toStringAsFixed(0)}%).');
    liveBullets.add('Bid/ask spread: ${liq.bidAskSpread.toStringAsFixed(4)}; volume ${liq.volume}; open interest ${liq.openInterest}.');

    // Fold top live-aware recommendations into bullets (top 2)
    final topRecs = List.of(recs.recommendations)..sort((a, b) => a.priority.compareTo(b.priority));
    for (final r in topRecs.take(2)) {
      liveBullets.add('Recommendation (${r.category}): ${r.message}');
    }

    // Outlook: synthesize live guidance combining base outlook and top rec
    final outlookParts = <String>[];
    outlookParts.add(base.outlook);
    if (topRecs.isNotEmpty) {
      outlookParts.add('Actionable: ${topRecs.first.message}');
    }
    final liveOutlook = outlookParts.join(' ');

    return StrategyNarrative(
      title: base.title,
      summary: liveSummary,
      bullets: [...liveBullets, ...base.bullets],
      outlook: liveOutlook,
      generatedAt: DateTime.now().toUtc(),
    );
  }
}

class StrategyNarrative {
  final String title;
  final String summary;
  final List<String> bullets;
  final String outlook;
  final DateTime generatedAt;

  const StrategyNarrative({
    required this.title,
    required this.summary,
    required this.bullets,
    required this.outlook,
    required this.generatedAt,
  });
}

/// Pure, deterministic narrative generator.
/// Accepts an optional `StrategyRecommendationsBundle` to enrich the narrative.
StrategyNarrative generateNarrative(StrategyContext ctx, {StrategyRecommendationsBundle? recsBundle}) {
  // Title
  final title = 'Strategy Story';

  // Tone mapping from healthScore
  final health = ctx.healthScore;
  final healthLabel = health >= 75
      ? 'Stable'
      : (health >= 50 ? 'Fragile' : 'At Risk');

  // Regime phrasing
  final regime = ctx.currentRegime.toLowerCase();
  final regimePhrase = regime == 'uptrend'
      ? 'strength'
      : (regime == 'downtrend' ? 'pressure' : 'neutral conditions');

  // Recent cycles summary
  final cycles = ctx.recentCycles;
  String cycleSentence;
  if (cycles.isEmpty) {
    cycleSentence = 'No recent cycle data is available.';
  } else {
    final avgPnl = _mean(cycles.map((c) => c.pnl).toList());
    final positive = avgPnl >= 0;
    final trend = positive ? 'delivered gains' : 'underperformed';
    cycleSentence = 'Over the last ${cycles.length} cycles the strategy has $trend (avg PnL ${avgPnl.toStringAsFixed(2)}).';
  }

  // Summary sentences (2-3 sentences)
  final summaryParts = <String>[];
  summaryParts.add(cycleSentence);
  summaryParts.add('Current market is $regime, described as $regimePhrase.');
  summaryParts.add('Overall health is $healthLabel (score $health).');
  final summary = summaryParts.join(' ');

  // Bullets: build key insights
  final bullets = <String>[];

  // discipline trend
  if (ctx.disciplineTrend.isNotEmpty) {
    final last = ctx.disciplineTrend.last;
    final prev = ctx.disciplineTrend.length >= 2 ? ctx.disciplineTrend[ctx.disciplineTrend.length - 2] : last;
    bullets.add('Discipline: ${prev} → ${last}.');
  }

  // health change implied by healthScore only
  bullets.add('Health score: $health.');

  // backtest insights
  final bt = ctx.backtestComparison;
  if (bt != null) {
    if (bt.bestConfig != null && bt.bestConfig!.isNotEmpty) {
      final parts = <String>[];
      if (bt.bestConfig!.containsKey('dte')) parts.add('DTE ${bt.bestConfig!['dte']}');
      if (bt.bestConfig!.containsKey('delta')) parts.add('delta ${bt.bestConfig!['delta']}');
      if (parts.isNotEmpty) bullets.add('Backtests favor: ${parts.join(', ')}.');
    }
    if (bt.weakConfig != null && bt.weakConfig!.isNotEmpty) {
      bullets.add('Backtests show weak configs that may underperform in some regimes.');
    }
  }

  // regime weaknesses
  if (ctx.recentCycles.any((c) => c.regime != null && c.regime!.toLowerCase() == 'downtrend')) {
    bullets.add('Strategy shows degradation in downtrend cycles.');
  }

  // Recommendations enrichment
  if (recsBundle != null && recsBundle.recommendations.isNotEmpty) {
    // pick top 2 by priority (lower is higher priority)
    final top = List.of(recsBundle.recommendations)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final take = top.take(2).toList();
    for (final r in take) {
      final phrased = switch (r.category) {
        'risk' => 'Risk: ${r.message}',
        'parameter' => 'Parameter suggestion: ${r.message}',
        'regime' => 'Regime note: ${r.message}',
        'discipline' => 'Discipline: ${r.message}',
        'consistency' => 'Consistency: ${r.message}',
        _ => r.message,
      };
      bullets.add(phrased);
    }
  }

  // Recommendations shortlisting: top 2
  if (ctx.recentCycles.isNotEmpty || bt != null) {
    final recs = <String>[];
    // Prefer recommendations that match rules in recommendations engine when present
    // (no direct recommendations here; user can extend to pass them in)
    if (ctx.drawdown > 0.15) recs.add('Consider lowering trade frequency due to drawdown.');
    if (recs.isNotEmpty) bullets.addAll(recs);
  }

  // Outlook: synthesize forward guidance
  final outlookParts = <String>[];
  if (health >= 75) {
    outlookParts.add('Positioning is reasonable; maintain current approach with attention to risk limits.');
  } else if (health >= 50) {
    outlookParts.add('Be cautious: consider modest size reductions and tighter deltas.');
  } else {
    outlookParts.add('Take defensive actions: reduce size and tighten risk parameters.');
  }
  if (regime == 'downtrend') outlookParts.add('Prefer defensive structures while the downtrend persists.');

  // If we have recommendations, fold top recommendation into outlook
  if (recsBundle != null && recsBundle.recommendations.isNotEmpty) {
    final top = List.of(recsBundle.recommendations)..sort((a, b) => a.priority.compareTo(b.priority));
    final first = top.first;
    outlookParts.add('Top recommendation: ${first.message}');
  }

  final outlook = outlookParts.join(' ');

  return StrategyNarrative(
    title: title,
    summary: summary,
    bullets: bullets,
    outlook: outlook,
    generatedAt: DateTime.now().toUtc(),
  );
}

double _mean(List<double> xs) => xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;
