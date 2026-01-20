class StrategyCyclePerformance {
  final double realizedPnl;
  final double unrealizedPnl;
  final double cycleReturn; // optional, % of risk or capital
  final double winRate;
  final double maxDrawdown;
  final Map<String, dynamic>? bestTrade;
  final Map<String, dynamic>? worstTrade;

  const StrategyCyclePerformance({
    required this.realizedPnl,
    required this.unrealizedPnl,
    required this.cycleReturn,
    required this.winRate,
    required this.maxDrawdown,
    required this.bestTrade,
    required this.worstTrade,
  });
}

class StrategyPerformanceAnalyzer {
  /// executions: list of trade summaries from StrategyCycleService._executionSummary
  static StrategyCyclePerformance computeCyclePerformance({
    required List<Map<String, dynamic>> executions,
  }) {
    if (executions.isEmpty) {
      return const StrategyCyclePerformance(
        realizedPnl: 0,
        unrealizedPnl: 0,
        cycleReturn: 0,
        winRate: 0,
        maxDrawdown: 0,
        bestTrade: null,
        worstTrade: null,
      );
    }

    double realized = 0;
    double unrealized = 0; // placeholder, can be wired to pricing later
    int wins = 0;
    int losses = 0;

    double equity = 0;
    double peakEquity = 0;
    double maxDrawdown = 0;

    Map<String, dynamic>? bestTrade;
    Map<String, dynamic>? worstTrade;
    double bestPnl = double.negativeInfinity;
    double worstPnl = double.infinity;

    for (final e in executions) {
      final type = (e['type'] ?? '').toString().toUpperCase();
      final premium = ((e['premium'] as num?) ?? 0).toDouble();
      final qty = ((e['qty'] as num?) ?? 1).toDouble();

      // Simple options PnL approximation: premium * 100 * qty
      double tradePnl = 0;
      if (type.contains('SELL')) {
        tradePnl = premium * 100 * qty;
      } else if (type.contains('BUY')) {
        tradePnl = -premium * 100 * qty;
      }

      realized += tradePnl;
      equity += tradePnl;

      if (equity > peakEquity) {
        peakEquity = equity;
      }
      final drawdown = peakEquity - equity;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }

      if (tradePnl > 0) {
        wins++;
      } else if (tradePnl < 0) {
        losses++;
      }

      if (tradePnl > bestPnl) {
        bestPnl = tradePnl;
        bestTrade = e;
      }
      if (tradePnl < worstPnl) {
        worstPnl = tradePnl;
        worstTrade = e;
      }
    }

    final totalTrades = wins + losses;
    final winRate = totalTrades == 0 ? 0.0 : wins / totalTrades;

    // cycleReturn: for now, just realized PnL; later you can divide by capital/risk.
    final cycleReturn = realized;

    return StrategyCyclePerformance(
      realizedPnl: realized,
      unrealizedPnl: unrealized,
      cycleReturn: cycleReturn,
      winRate: winRate,
      maxDrawdown: maxDrawdown,
      bestTrade: bestTrade,
      worstTrade: worstTrade,
    );
  }
}
