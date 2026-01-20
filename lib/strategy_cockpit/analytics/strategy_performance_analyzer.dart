import 'package:riskform/strategy_cockpit/models/strategy_health_snapshot.dart';

class StrategyPerformanceAnalyzer {
  // ------------------------------------------------------------
  // Win Rate
  // ------------------------------------------------------------
  static double computeWinRate(StrategyHealthSnapshot snapshot) {
    final cycles = snapshot.cycleSummaries;
    if (cycles.isEmpty) return 0;

    final wins = cycles.where((c) => (c['pnl'] ?? 0) > 0).length;
    return wins / cycles.length;
  }

  // ------------------------------------------------------------
  // Max Drawdown (based on PnL trend)
  // ------------------------------------------------------------
  static double computeMaxDrawdown(StrategyHealthSnapshot snapshot) {
    final trend = snapshot.pnlTrend;
    if (trend.isEmpty) return 0;

    double peak = trend.first;
    double maxDD = 0;

    for (final value in trend) {
      if (value > peak) peak = value;
      final dd = peak - value;
      if (dd > maxDD) maxDD = dd;
    }

    return maxDD;
  }

  // ------------------------------------------------------------
  // Best Cycle (highest PnL)
  // ------------------------------------------------------------
  static Map<String, dynamic>? computeBestCycle(
      StrategyHealthSnapshot snapshot) {
    if (snapshot.cycleSummaries.isEmpty) return null;

    Map<String, dynamic>? best;
    double bestPnl = double.negativeInfinity;

    for (final cycle in snapshot.cycleSummaries) {
      final pnl = (cycle['pnl'] ?? 0).toDouble();
      if (pnl > bestPnl) {
        bestPnl = pnl;
        best = cycle;
      }
    }

    return best;
  }

  // ------------------------------------------------------------
  // Worst Cycle (lowest PnL)
  // ------------------------------------------------------------
  static Map<String, dynamic>? computeWorstCycle(
      StrategyHealthSnapshot snapshot) {
    if (snapshot.cycleSummaries.isEmpty) return null;

    Map<String, dynamic>? worst;
    double worstPnl = double.infinity;

    for (final cycle in snapshot.cycleSummaries) {
      final pnl = (cycle['pnl'] ?? 0).toDouble();
      if (pnl < worstPnl) {
        worstPnl = pnl;
        worst = cycle;
      }
    }

    return worst;
  }

  // ------------------------------------------------------------
  // Average PnL (optional helper)
  // ------------------------------------------------------------
  static double computeAveragePnl(StrategyHealthSnapshot snapshot) {
    final cycles = snapshot.cycleSummaries;
    if (cycles.isEmpty) return 0;

    final total = cycles.fold<double>(
      0,
      (sum, c) => sum + (c['pnl'] ?? 0).toDouble(),
    );

    return total / cycles.length;
  }

  // ------------------------------------------------------------
  // Profit Factor (optional helper)
  // ------------------------------------------------------------
  static double computeProfitFactor(StrategyHealthSnapshot snapshot) {
    final cycles = snapshot.cycleSummaries;
    if (cycles.isEmpty) return 0;

    double grossProfit = 0;
    double grossLoss = 0;

    for (final cycle in cycles) {
      final pnl = (cycle['pnl'] ?? 0).toDouble();
      if (pnl > 0) grossProfit += pnl;
      if (pnl < 0) grossLoss += pnl.abs();
    }

    if (grossLoss == 0) return grossProfit > 0 ? double.infinity : 0;

    return grossProfit / grossLoss;
  }
}
