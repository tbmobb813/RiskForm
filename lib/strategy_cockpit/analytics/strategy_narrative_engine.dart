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
    final healthTone = _healthTone(context.healthScore);
    final regimePhrase = _regimePhrase(regime, vol, liq);
    final summary = _buildSummary(healthTone, regimePhrase, context.recentCycles);

    final historyInsights = _historyBullets(context, context.recentCycles, context.backtestComparison);
    final liveInsights = _liveBullets(regime, vol, liq);
    final recSummary = _summarizeTopRecommendations(recs);

    final outlookBase = _buildOutlook(healthTone, regimePhrase, recSummary);
    final finalOutlook = '$outlookBase Actionable: $recSummary';

    return StrategyNarrative(
      title: 'Current Strategy Story',
      summary: summary,
      bullets: [
        ...historyInsights,
        ...liveInsights,
      ],
      outlook: finalOutlook,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  String _healthTone(int healthScore) {
    if (healthScore >= 80) return 'stable';
    if (healthScore >= 60) return 'fragile';
    return 'at risk';
  }

  String _regimePhrase(
    MarketRegimeSnapshot regime,
    MarketVolatilitySnapshot vol,
    MarketLiquiditySnapshot liq,
  ) {
    final trendWord = (regime.trend == 'uptrend')
        ? 'an uptrend'
        : (regime.trend == 'downtrend' ? 'a downtrend' : 'a sideways regime');

    final volWord = (regime.volatility == 'high')
        ? 'high volatility'
        : (regime.volatility == 'low' ? 'low volatility' : 'normal volatility');

    final liqWord = (regime.liquidity == 'thin')
        ? 'thin liquidity'
        : (regime.liquidity == 'deep' ? 'deep liquidity' : 'normal liquidity');

    return '$volWord $trendWord with $liqWord';
  }

  String _buildSummary(
    String healthTone,
    String regimePhrase,
    List<CycleSummary> cycles,
  ) {
    final recent = cycles.take(3).toList();
    final pnlDesc = _recentPnlPhrase(recent);
    final discDesc = _recentDisciplinePhrase(recent);

    return 'Over the last few cycles, the strategy has shown $pnlDesc with $discDesc. Current market conditions are $regimePhrase.';
  }

  String _recentPnlPhrase(List<CycleSummary> cycles) {
    if (cycles.isEmpty) return 'limited observable performance';

    final pnls = cycles.map((c) => c.pnl).toList();
    final avg = pnls.reduce((a, b) => a + b) / pnls.length;

    if (avg > 0) return 'generally positive performance';
    if (avg < 0) return 'recent pressure on performance';
    return 'mixed performance';
  }

  String _recentDisciplinePhrase(List<CycleSummary> cycles) {
    if (cycles.length < 2) return 'limited discipline data';

    final first = cycles.first.disciplineScore;
    final last = cycles.last.disciplineScore;
    final delta = last - first;

    if (delta > 5) return 'improving discipline';
    if (delta < -5) return 'slipping discipline';
    return 'relatively stable discipline';
  }

  List<String> _historyBullets(
    StrategyContext context,
    List<CycleSummary> cycles,
    BacktestSummary? backtests,
  ) {
    final bullets = <String>[];

    // Health trend (using disciplineTrend as a proxy for trend)
    if (context.disciplineTrend.isNotEmpty && context.disciplineTrend.length >= 2) {
      final first = context.disciplineTrend.first;
      final last = context.disciplineTrend.last;
      final delta = (last - first).round();
      final dir = delta > 0 ? 'improved' : delta < 0 ? 'declined' : 'remained stable';
      bullets.add('Health score has $dir from $first to $last.');
    }

    // Recent cycles
    if (cycles.isNotEmpty) {
      final last = cycles.last;
      final pnl = last.pnl;
      bullets.add('Most recent cycle closed with PnL of ${pnl.toStringAsFixed(2)} and discipline score ${last.disciplineScore}.');
    }

    // Backtest insights
    if (backtests != null) {
      final best = backtests.bestConfig;
      final worst = backtests.weakConfig;
      if (best != null && best.isNotEmpty) {
        bullets.add('Backtests highlight strong performance around ${_configPhrase(best)}.');
      }
      if (worst != null && worst.isNotEmpty) {
        bullets.add('Weak configurations appear around ${_configPhrase(worst)}.');
      }
    }

    return bullets;
  }

  String _configPhrase(Map<String, dynamic> cfg) {
    final dte = cfg['dte'];
    final delta = cfg['delta'];
    final width = cfg['width'];
    final parts = <String>[];
    if (dte != null) parts.add('DTE $dte');
    if (delta != null) parts.add('delta ${_formatNum(delta)}');
    if (width != null) parts.add('width $width');
    return parts.join(', ');
  }

  String _formatNum(dynamic v) {
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }

  List<String> _liveBullets(
    MarketRegimeSnapshot regime,
    MarketVolatilitySnapshot vol,
    MarketLiquiditySnapshot liq,
  ) {
    final bullets = <String>[];

    bullets.add('Current regime is ${regime.trend} with ${regime.volatility} volatility and ${regime.liquidity} liquidity.');
    bullets.add('Current IV Rank is ${vol.ivRank.toStringAsFixed(0)}, indicating ${_ivRankPhrase(vol.ivRank)}.');
    bullets.add('Bid/ask spread is ${liq.bidAskSpread.toStringAsFixed(2)}, with volume ${liq.volume} and open interest ${liq.openInterest}.');

    return bullets;
  }

  String _ivRankPhrase(double ivRank) {
    if (ivRank >= 70) return 'elevated volatility conditions';
    if (ivRank <= 30) return 'muted volatility conditions';
    return 'normal volatility conditions';
  }

  String _summarizeTopRecommendations(StrategyRecommendationsBundle recs) {
    if (recs.recommendations.isEmpty) {
      return 'No specific parameter or risk changes are currently suggested.';
    }

    final sorted = [...recs.recommendations]..sort((a, b) => a.priority.compareTo(b.priority));

    final top = sorted.take(3).toList();
    final messages = top.map((r) => r.message).toList();

    if (messages.length == 1) return messages.first;
    if (messages.length == 2) return "${messages[0]} Additionally, ${messages[1]}";
    return "${messages[0]} Additionally, ${messages[1]} Finally, ${messages[2]}";
  }

  String _buildOutlook(
    String healthTone,
    String regimePhrase,
    String recSummary,
  ) {
    final tonePrefix = (healthTone == 'stable')
        ? 'Given the current stable condition of the strategy and'
        : (healthTone == 'fragile')
            ? 'Given the fragile condition of the strategy and'
            : 'Given the at‑risk condition of the strategy and';

    return '$tonePrefix $regimePhrase, $recSummary';
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
    bullets.add('Discipline: $prev → $last.');
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
