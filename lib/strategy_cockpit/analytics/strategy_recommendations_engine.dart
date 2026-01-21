// Pure, deterministic Strategy Recommendations Engine
// Minimal, production-oriented implementation based on Phase 5.7 spec
import 'package:riskform/services/market_data_models.dart';

class StrategyRecommendation {
  final String category; // "risk", "parameter", "regime", "discipline", "consistency"
  final String message;
  final int priority; // 1 (highest) .. 5 (lowest)

  const StrategyRecommendation({
    required this.category,
    required this.message,
    required this.priority,
  });

  @override
  String toString() => '[$category|p$priority] $message';
}

class StrategyRecommendationsBundle {
  final List<StrategyRecommendation> recommendations;
  final DateTime generatedAt;

  const StrategyRecommendationsBundle({
    required this.recommendations,
    required this.generatedAt,
  });
}

class CycleSummary {
  final int disciplineScore; // 0-100
  final double pnl;
  final String? regime;

  const CycleSummary({required this.disciplineScore, required this.pnl, this.regime});
}

class BacktestSummary {
  final Map<String, dynamic>? bestConfig; // lightweight container (e.g. {"dte":30, "delta":0.18})
  final Map<String, dynamic>? weakConfig;
  final String? summaryNote;

  const BacktestSummary({this.bestConfig, this.weakConfig, this.summaryNote});
}

class Constraints {
  final int maxRisk;
  final int maxPositions;
  final List<int>? allowedDteRange; // [min,max]
  final List<double>? allowedDeltaRange; // [min,max]

  const Constraints({
    required this.maxRisk,
    required this.maxPositions,
    this.allowedDteRange,
    this.allowedDeltaRange,
  });
}

class StrategyContext {
  final int healthScore; // 0-100
  final List<double> pnlTrend; // recent returns (percent or abs)
  final List<int> disciplineTrend; // recent discipline scores
  final List<CycleSummary> recentCycles;
  final BacktestSummary? backtestComparison;
  final Constraints constraints;
  final String currentRegime;
  final double drawdown; // 0-1

  const StrategyContext({
    required this.healthScore,
    required this.pnlTrend,
    required this.disciplineTrend,
    required this.recentCycles,
    required this.constraints,
    required this.currentRegime,
    required this.drawdown,
    this.backtestComparison,
  });
}

StrategyRecommendationsBundle generateRecommendations(StrategyContext ctx) {
  final List<StrategyRecommendation> recs = [];

  // 1) Parameter recommendations from backtest bestConfig
  final best = ctx.backtestComparison?.bestConfig;
  if (best != null && best.isNotEmpty) {
    final parts = <String>[];
    if (best.containsKey('dte')) parts.add('DTE ${best['dte']}');
    if (best.containsKey('delta')) parts.add('delta ${best['delta']}');
    if (best.containsKey('width')) parts.add('width ${best['width']}');
    final msg = 'Backtests favor: ${parts.join(', ')}.';
    recs.add(StrategyRecommendation(category: 'parameter', message: msg, priority: 3));
  }

  // 2) Risk recommendations based on healthScore and drawdown
  if (ctx.healthScore < 60) {
    recs.add(StrategyRecommendation(
        category: 'risk',
        message: 'Health score ${ctx.healthScore} — reduce position size by 20–40%.',
        priority: 1));
  }
  if (ctx.drawdown > 0.15) {
    recs.add(StrategyRecommendation(
        category: 'risk',
        message: 'Drawdown ${(ctx.drawdown * 100).toStringAsFixed(0)}% — consider lowering trade frequency.',
        priority: 2));
  }

  // 3) Regime recommendations
  final regime = ctx.currentRegime.toLowerCase();
  if (regime == 'uptrend') {
    recs.add(StrategyRecommendation(
        category: 'regime', message: 'Uptrend — favor premium selling when strength appears.', priority: 3));
  } else if (regime == 'downtrend') {
    recs.add(StrategyRecommendation(
        category: 'regime', message: 'Downtrend — shift to defensive structures or reduce exposure.', priority: 2));
  } else if (regime == 'sideways' || regime == 'flat') {
    recs.add(StrategyRecommendation(
        category: 'regime', message: 'Sideways market — neutral income strategies preferred.', priority: 4));
  }

  // 4) Discipline recommendations
  final lastDisc = ctx.disciplineTrend.isNotEmpty ? ctx.disciplineTrend.last : null;
  if (lastDisc != null && lastDisc < 60) {
    recs.add(StrategyRecommendation(
        category: 'discipline', message: 'Recent discipline low ($lastDisc) — slow down and review journal notes.', priority: 1));
  }
  // Detect over-adjustment: many adjustments implied by high variance in disciplineTrend
  if (ctx.disciplineTrend.length >= 3) {
    final changeCount = _countSignificantChanges(ctx.disciplineTrend, threshold: 10);
    if (changeCount >= 2) {
      recs.add(StrategyRecommendation(
          category: 'discipline', message: 'Frequent adjustments detected — avoid intracycle changes.', priority: 2));
    }
  }

  // 5) Consistency recommendations
  final varPnl = _variance(ctx.pnlTrend);
  if (varPnl > 0.05) {
    recs.add(StrategyRecommendation(
        category: 'consistency', message: 'High PnL variance — consider narrowing width or tightening entries.', priority: 2));
  }

  // 6) Recent cycles insights
  if (ctx.recentCycles.isNotEmpty) {
    final poorCycles = ctx.recentCycles.where((c) => c.disciplineScore < 60 || c.pnl < 0).length;
    if (poorCycles >= (ctx.recentCycles.length / 2).ceil()) {
      recs.add(StrategyRecommendation(
          category: 'risk', message: 'Multiple recent cycles underperforming — reduce size and review constraints.', priority: 1));
    }
  }

  // Ensure deterministic ordering by category and priority
  recs.sort((a, b) {
    final pc = a.priority.compareTo(b.priority);
    if (pc != 0) return pc;
    return a.category.compareTo(b.category);
  });

  return StrategyRecommendationsBundle(recommendations: recs, generatedAt: DateTime.now().toUtc());
}

double _mean(List<double> xs) => xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;
double _variance(List<double> xs) {
  if (xs.length < 2) return 0.0;
  final m = _mean(xs);
  final s = xs.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b);
  return s / xs.length;
}

int _countSignificantChanges(List<int> seq, {required int threshold}) {
  if (seq.length < 2) return 0;
  var count = 0;
  for (var i = 1; i < seq.length; i++) {
    if ((seq[i] - seq[i - 1]).abs() >= threshold) count++;
  }
  return count;
}

// Live-aware Strategy Recommendations Engine (Phase 6.4)

class StrategyRecommendationsEngine {
  const StrategyRecommendationsEngine();

  Future<StrategyRecommendationsBundle> generate({
    required StrategyContext context,
    required MarketRegimeSnapshot regime,
    required MarketVolatilitySnapshot vol,
    required MarketLiquiditySnapshot liq,
  }) async {
    // Start with the deterministic base recommendations
    final base = generateRecommendations(context);

    final List<StrategyRecommendation> out = [];

    // Copy base recommendations so we can mutate priority/message
    for (final r in base.recommendations) {
      out.add(StrategyRecommendation(category: r.category, message: r.message, priority: r.priority));
    }

    // Trend-aware modifiers
    final trend = regime.trend.toLowerCase();
    if (trend == 'uptrend') {
      // If backtest suggests very low delta, recommend slightly higher delta
      final bestDelta = context.backtestComparison?.bestConfig?['delta'];
      if (bestDelta is num && bestDelta.toDouble() < 0.10) {
        out.add(StrategyRecommendation(
            category: 'parameter',
            message: 'Uptrend — consider raising target delta to 0.15–0.20 for premium selling.',
            priority: 3));
      } else {
        out.add(StrategyRecommendation(category: 'regime', message: 'Uptrend — favor premium selling with tighter deltas.', priority: 3));
      }
    } else if (trend == 'downtrend') {
      out.add(StrategyRecommendation(category: 'risk', message: 'Downtrend — reduce position size by 20–30%.', priority: 1));
      final bestWidth = context.backtestComparison?.bestConfig?['width'];
      if (bestWidth is num && bestWidth.toDouble() < 1.0) {
        out.add(StrategyRecommendation(category: 'parameter', message: 'Downtrend — widen structure width to absorb moves.', priority: 2));
      }
    } else if (trend == 'sideways' || trend == 'flat') {
      out.add(StrategyRecommendation(category: 'regime', message: 'Sideways — neutral income and delta‑neutral structures preferred.', priority: 4));
    }

    // Volatility-aware modifiers
    if (vol.ivRank >= 70) {
      out.add(StrategyRecommendation(category: 'risk', message: 'High volatility (IVR ≥70) — reduce size and widen width.', priority: 1));
      // Bump priority on any existing risk recs
      for (var i = 0; i < out.length; i++) {
        if (out[i].category == 'risk') {
          out[i] = StrategyRecommendation(category: out[i].category, message: out[i].message, priority: _clampPriority(out[i].priority - 1));
        }
      }
    } else if (vol.ivRank <= 30) {
      out.add(StrategyRecommendation(category: 'parameter', message: 'Low volatility (IVR ≤30) — consider tighter width and shorter DTE.', priority: 3));
    }

    // Liquidity-aware modifiers (regime contains liquidity label; snapshot contains spreads)
    final liqStr = regime.liquidity.toLowerCase();
    if (liqStr == 'thin') {
      out.add(StrategyRecommendation(category: 'risk', message: 'Thin liquidity — reduce size and avoid complex structures.', priority: 1));
      if (liq.bidAskSpread > 0.05) {
        out.add(StrategyRecommendation(category: 'risk', message: 'Wide bid/ask spread — expect slippage; prefer smaller sizes.', priority: 1));
      }
    } else if (liqStr == 'deep') {
      out.add(StrategyRecommendation(category: 'parameter', message: 'Deep liquidity — normal sizing acceptable.', priority: 4));
    }

    // Priority model: combination rules
    final lastDisc = context.disciplineTrend.isNotEmpty ? context.disciplineTrend.last : null;
    if (trend == 'downtrend' && vol.ivRank >= 70 && lastDisc != null && lastDisc < 60) {
      // escalate all risk recommendations to highest priority
      for (var i = 0; i < out.length; i++) {
        if (out[i].category == 'risk') {
          out[i] = StrategyRecommendation(category: out[i].category, message: out[i].message, priority: 1);
        }
      }
    }

    if (trend == 'uptrend' && vol.ivRank >= 70 && context.healthScore >= 70) {
      // favor parameter recommendations
      for (var i = 0; i < out.length; i++) {
        if (out[i].category == 'parameter') {
          out[i] = StrategyRecommendation(category: out[i].category, message: out[i].message, priority: _clampPriority(out[i].priority - 1));
        }
      }
    }

    // Deduplicate by message and choose lowest priority for duplicates
    final Map<String, StrategyRecommendation> dedup = {};
    for (final r in out) {
      final key = '${r.category}:${r.message}';
      if (!dedup.containsKey(key) || r.priority < dedup[key]!.priority) {
        dedup[key] = r;
      }
    }

    final finalList = dedup.values.toList();
    finalList.sort((a, b) {
      final pc = a.priority.compareTo(b.priority);
      if (pc != 0) return pc;
      return a.category.compareTo(b.category);
    });

    return StrategyRecommendationsBundle(recommendations: finalList, generatedAt: DateTime.now().toUtc());
  }

  int _clampPriority(int p) => p < 1 ? 1 : (p > 5 ? 5 : p);
}

