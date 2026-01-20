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

  // ------------------------------------------------------------
  // Cycle-level adapter (static) for Execution → Cycle wiring
  // ------------------------------------------------------------
  static CyclePerformanceResult computeCyclePerformance({
    required List<Map<String, dynamic>> executions,
  }) {
    double realized = 0;
    int wins = 0;
    int total = executions.length;

    Map<String, dynamic>? best;
    Map<String, dynamic>? worst;
    double bestVal = double.negativeInfinity;
    double worstVal = double.infinity;

    for (final e in executions) {
      final type = (e['type'] ?? '').toString().toUpperCase();
      final premium = (e['premium'] ?? 0).toDouble();
      final qty = (e['qty'] ?? 1).toDouble();
      final pnl = (type.contains('SELL') ? premium * 100 * qty : -premium * 100 * qty);

      realized += pnl;

      if (pnl > 0) wins++;

      if (pnl > bestVal) {
        bestVal = pnl;
        best = e;
      }
      if (pnl < worstVal) {
        worstVal = pnl;
        worst = e;
      }
    }

    final winRate = total == 0 ? 0.0 : wins / total;

    return CyclePerformanceResult(
      realizedPnl: realized,
      unrealizedPnl: 0.0,
      cycleReturn: 0.0,
      winRate: winRate,
      maxDrawdown: 0.0,
      bestTrade: best,
      worstTrade: worst,
    );
  }
}

class CyclePerformanceResult {
  final double realizedPnl;
  final double unrealizedPnl;
  final double cycleReturn;
  final double winRate;
  final double maxDrawdown;
  final Map<String, dynamic>? bestTrade;
  final Map<String, dynamic>? worstTrade;

  CyclePerformanceResult({
    required this.realizedPnl,
    required this.unrealizedPnl,
    required this.cycleReturn,
    required this.winRate,
    required this.maxDrawdown,
    this.bestTrade,
    this.worstTrade,
  });
}

/// Adapter for cycle-level performance computation.
extension StrategyPerformanceAdapter on StrategyPerformanceAnalyzer {
  static CyclePerformanceResult computeCyclePerformance({
    required List<Map<String, dynamic>> executions,
  }) {
    double realized = 0;
    int wins = 0;
    int total = executions.length;

    Map<String, dynamic>? best;
    Map<String, dynamic>? worst;
    double bestVal = double.negativeInfinity;
    double worstVal = double.infinity;

    for (final e in executions) {
      final type = (e['type'] ?? '').toString().toUpperCase();
      final premium = (e['premium'] ?? 0).toDouble();
      final qty = (e['qty'] ?? 1).toDouble();
      final pnl = (type.contains('SELL') ? premium * 100 * qty : -premium * 100 * qty);

      realized += pnl;

      if (pnl > 0) wins++;

      if (pnl > bestVal) {
        bestVal = pnl;
        best = e;
      }
      if (pnl < worstVal) {
        worstVal = pnl;
        worst = e;
      }
    }

    final winRate = total == 0 ? 0.0 : wins / total;

    return CyclePerformanceResult(
      realizedPnl: realized,
      unrealizedPnl: 0.0,
      cycleReturn: 0.0,
      winRate: winRate,
      maxDrawdown: 0.0,
      bestTrade: best,
      worstTrade: worst,
    );
  }
}
