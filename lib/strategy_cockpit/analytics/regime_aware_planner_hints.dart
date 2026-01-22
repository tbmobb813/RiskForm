import 'package:flutter/material.dart';
import 'dart:math';
import 'strategy_recommendations_engine.dart';

/// Planner input snapshot (user-entered values)
class PlannerState {
  final int dte;
  final double delta;
  final double width;
  final int size;
  final String type;

  const PlannerState({
    required this.dte,
    required this.delta,
    required this.width,
    required this.size,
    required this.type,
  });
}

class PlannerHint {
  final String field; // e.g. "dte", "delta", "width", "size", "type"
  final String message;
  final String severity; // "info", "warning", "danger"

  const PlannerHint({required this.field, required this.message, required this.severity});
}

class PlannerHintBundle {
  final List<PlannerHint> hints;
  final Map<String, RangeValues> recommendedRanges;
  // Optional weak configuration zones (e.g. ranges to avoid)
  final Map<String, RangeValues> weakRanges;
  // Best-config exact points (backtest best suggestions) as numeric values
  final Map<String, double> bestPoints;

  const PlannerHintBundle({
    required this.hints,
    required this.recommendedRanges,
    this.weakRanges = const {},
    this.bestPoints = const {},
  });
}

/// Pure function generating planner hints from current planner state and
/// strategy context (health, recommendations, constraints, backtests).
PlannerHintBundle generateHints(PlannerState state, StrategyContext ctx) {
  final hints = <PlannerHint>[];
  final ranges = <String, RangeValues>{};
  final weakRanges = <String, RangeValues>{};
  final bestPoints = <String, double>{};

  final regime = ctx.currentRegime.toLowerCase();

  // --- Regime Rules ---
  if (regime == 'uptrend') {
    // recommend tighter deltas
    ranges['delta'] = const RangeValues(0.15, 0.20);
    hints.add(const PlannerHint(field: 'delta', message: 'Uptrend detected — tighter deltas favored (0.15–0.20).', severity: 'info'));
  } else if (regime == 'downtrend') {
    // warn if delta too large
    if (state.delta > 0.25) {
      hints.add(PlannerHint(field: 'delta', message: 'Downtrend — delta > 0.25 is risky for this regime.', severity: 'warning'));
    }
    // suggest defensive width (units same as planner width)
    final defensiveMinWidth = 20.0;
    if (state.width < defensiveMinWidth) {
      hints.add(PlannerHint(field: 'width', message: 'Downtrend — consider wider width for defensive posture.', severity: 'info'));
      ranges['width'] = RangeValues(defensiveMinWidth, max(state.width, defensiveMinWidth));
    }
  } else if (regime == 'sideways' || regime == 'flat') {
    hints.add(const PlannerHint(field: 'type', message: 'Sideways market — neutral income structures (IC, strangle) preferred.', severity: 'info'));
  }

  // --- Backtest Rules ---
  final best = ctx.backtestComparison?.bestConfig;
  final weak = ctx.backtestComparison?.weakConfig;
    if (best != null && best.isNotEmpty) {
    final parts = <String>[];
    if (best.containsKey('dte')) {
      final b = best['dte'];
      if (b is num) ranges['dte'] = RangeValues(b.toDouble(), b.toDouble());
        if (b is num) bestPoints['dte'] = b.toDouble();
      parts.add('DTE $b');
    }
    if (best.containsKey('delta')) {
      final b = best['delta'];
      if (b is num) ranges['delta'] = RangeValues(b.toDouble(), b.toDouble());
        if (b is num) bestPoints['delta'] = b.toDouble();
      parts.add('delta $b');
    }
    if (best.containsKey('width')) {
      final b = best['width'];
      if (b is num) ranges['width'] = RangeValues(b.toDouble(), b.toDouble());
        if (b is num) bestPoints['width'] = b.toDouble();
      parts.add('width $b');
    }
    hints.add(PlannerHint(field: 'backtest', message: 'Backtests favor: ${parts.join(', ')}.', severity: 'info'));
  }

  if (weak != null && weak.isNotEmpty) {
    // If weak config conflicts with current user input, warn
    if (weak.containsKey('delta')) {
      final w = weak['delta'];
      if (w is num && state.delta > w.toDouble()) {
        hints.add(PlannerHint(field: 'delta', message: 'Backtests show weakness at delta > $w — consider tightening.', severity: 'warning'));
        // mark weak zone for delta (we'll render as a red marker/range)
        weakRanges['delta'] = RangeValues(w.toDouble(), w.toDouble());
      }
    }
    if (weak.containsKey('dte')) {
      final w = weak['dte'];
      if (w is num && state.dte < w.toInt()) {
        hints.add(PlannerHint(field: 'dte', message: 'Backtests weak for DTE < $w in similar regimes.', severity: 'warning'));
        weakRanges['dte'] = RangeValues(w.toDouble(), w.toDouble());
      }
    }
  }

  // If the backtest indicates regime weakness for current regime, danger
  final bw = ctx.backtestComparison?.summaryNote;
  if (bw != null && bw.toLowerCase().contains(ctx.currentRegime.toLowerCase())) {
    hints.add(PlannerHint(field: 'backtest', message: 'Backtests indicate weaknesses for current regime.', severity: 'danger'));
  }

  // --- Discipline Rules ---
  final lastDisc = ctx.disciplineTrend.isNotEmpty ? ctx.disciplineTrend.last : null;
  if (lastDisc != null && lastDisc < 60) {
    if (state.size > 5) {
      hints.add(PlannerHint(field: 'size', message: 'Discipline slipping — reduce size relative to current (${state.size}).', severity: 'warning'));
    } else {
      hints.add(const PlannerHint(field: 'size', message: 'Discipline trend low — be conservative with sizing.', severity: 'info'));
    }
  }
  // detect downward trend in discipline
  if (ctx.disciplineTrend.length >= 3) {
    final recent = ctx.disciplineTrend.sublist(ctx.disciplineTrend.length - 3);
    if (recent[2] < recent[1] && recent[1] < recent[0]) {
      hints.add(const PlannerHint(field: 'discipline', message: 'Discipline trending downward — consider reducing size.', severity: 'info'));
    }
  }

  // --- Constraint Rules ---
  final c = ctx.constraints;
    if (c.allowedDeltaRange != null && c.allowedDeltaRange!.length == 2) {
    final minD = c.allowedDeltaRange![0];
    final maxD = c.allowedDeltaRange![1];
    if (state.delta < minD || state.delta > maxD) {
      hints.add(PlannerHint(field: 'delta', message: 'Delta ${state.delta} outside allowed range ($minD–$maxD).', severity: 'danger'));
    }
    ranges.putIfAbsent('delta', () => RangeValues(minD, maxD));
  }
  if (c.allowedDteRange != null && c.allowedDteRange!.length == 2) {
    final minT = c.allowedDteRange![0].toDouble();
    final maxT = c.allowedDteRange![1].toDouble();
    if (state.dte < minT || state.dte > maxT) {
      hints.add(PlannerHint(field: 'dte', message: 'DTE ${state.dte} outside allowed range (${minT.toInt()}–${maxT.toInt()}).', severity: 'warning'));
    }
    ranges.putIfAbsent('dte', () => RangeValues(minT, maxT));
  }

  // maxPositions / maxRisk checks are contextual; we only nudge if constraints are tight
  if (c.maxPositions <= 1 && state.size > 1) {
    hints.add(const PlannerHint(field: 'size', message: 'You are at max positions — cannot increase size further.', severity: 'danger'));
  }

  // --- Consistency Rules ---
  final varPnl = _variance(ctx.pnlTrend);
  if (varPnl > 0.05) {
    hints.add(const PlannerHint(field: 'width', message: 'High PnL variance — recommend narrowing width.', severity: 'info'));
    // propose narrower width
    ranges.putIfAbsent('width', () => RangeValues(10.0, 30.0));
  }

  // Deterministic ordering: severity (danger, warning, info) then field
  final severityRank = {'danger': 0, 'warning': 1, 'info': 2};
  hints.sort((a, b) {
    final sa = severityRank[a.severity] ?? 3;
    final sb = severityRank[b.severity] ?? 3;
    if (sa != sb) return sa.compareTo(sb);
    return a.field.compareTo(b.field);
  });

  return PlannerHintBundle(hints: hints, recommendedRanges: ranges, weakRanges: weakRanges, bestPoints: bestPoints);
}

double _mean(List<double> xs) => xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;
double _variance(List<double> xs) {
  if (xs.length < 2) return 0.0;
  final m = _mean(xs);
  final s = xs.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b);
  return s / xs.length;
}
