import '../models/strategy_health_snapshot.dart';

class StrategyRegimeAnalyzer {
  // ------------------------------------------------------------
  // Regime Performance Summary
  // Returns a map keyed by regime:
  // {
  //   "uptrend": { pnl, winRate, avgDiscipline },
  //   "downtrend": { ... },
  //   "sideways": { ... }
  // }
  // ------------------------------------------------------------
  static Map<String, Map<String, dynamic>> computeRegimePerformance(
      StrategyHealthSnapshot snapshot) {
    final cycles = snapshot.cycleSummaries;
    if (cycles.isEmpty) return {};

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    // Group cycles by regime
    for (final cycle in cycles) {
      final regime = cycle['regime'] ?? 'unknown';
      grouped.putIfAbsent(regime, () => []);
      grouped[regime]!.add(cycle);
    }

    // Compute metrics per regime
    final Map<String, Map<String, dynamic>> result = {};

    grouped.forEach((regime, list) {
      double totalPnl = 0;
      int wins = 0;
      double totalDiscipline = 0;

      for (final cycle in list) {
        final pnl = (cycle['pnl'] ?? 0).toDouble();
        final discipline = (cycle['disciplineScore'] ?? 0).toDouble();

        totalPnl += pnl;
        totalDiscipline += discipline;

        if (pnl > 0) wins++;
      
      }

      final winRate = list.isEmpty ? 0 : wins / list.length;
      final avgDiscipline = list.isEmpty ? 0 : totalDiscipline / list.length;

      result[regime] = {
        'pnl': totalPnl,
        'winRate': winRate,
        'avgDiscipline': avgDiscipline,
        'count': list.length,
      };
    });

    return result;
  }

  // ------------------------------------------------------------
  // Regime Weakness Flags
  // Returns a list of descriptive flags:
  // [
  //   "Underperforms in high volatility",
  //   "Discipline deteriorates in downtrend"
  // ]
  // ------------------------------------------------------------
  static List<String> computeRegimeWeaknesses(
      StrategyHealthSnapshot snapshot) {
    final performance = computeRegimePerformance(snapshot);
    final List<String> flags = [];

    performance.forEach((regime, stats) {
      final pnl = stats['pnl'] ?? 0.0;
      final winRate = stats['winRate'] ?? 0.0;
      final discipline = stats['avgDiscipline'] ?? 0.0;

      // Weak PnL
      if (pnl < 0) {
        flags.add("Underperforms in $regime regimes");
      }

      // Weak win rate
      if (winRate < 0.4) {
        flags.add("Low win rate in $regime regimes");
      }

      // Weak discipline
      if (discipline < 70) {
        flags.add("Discipline deteriorates in $regime regimes");
      }
    });

    return flags;
  }

  // ------------------------------------------------------------
  // Current Regime Contextual Hint
  // Returns a single descriptive string:
  // "This strategy historically performs well in uptrend regimes."
  // ------------------------------------------------------------
  static String computeCurrentRegimeHint({
    required StrategyHealthSnapshot snapshot,
    required String? currentRegime,
  }) {
    if (currentRegime == null) return "";

    final performance = computeRegimePerformance(snapshot);
    final stats = performance[currentRegime];

    if (stats == null) {
      return "No historical data for the current regime.";
    }

    final pnl = stats['pnl'] ?? 0.0;
    final winRate = stats['winRate'] ?? 0.0;
    final discipline = stats['avgDiscipline'] ?? 0.0;

    if (pnl > 0 && winRate > 0.5) {
      return "This strategy historically performs well in $currentRegime regimes.";
    }

    if (pnl < 0 && winRate < 0.4) {
      return "This strategy has struggled in $currentRegime regimes.";
    }

    if (discipline < 70) {
      return "Discipline tends to slip in $currentRegime regimes.";
    }

    return "Performance in $currentRegime regimes has been mixed.";
  }

  // ------------------------------------------------------------
  // Cycle-level adapter (static) for Execution → Cycle wiring
  // ------------------------------------------------------------
  static CycleRegimeResult computeCycleRegime({
    required List<Map<String, dynamic>> executions,
    required String? currentRegime,
  }) {
    // Simple adapter: use currentRegime as dominant, score/align placeholders
    return CycleRegimeResult(
      dominantRegime: currentRegime,
      regimeScore: 0.0,
      regimeAlignment: 0.0,
    );
  }
}
class CycleRegimeResult {
  final String? dominantRegime;
  final double regimeScore;
  final double regimeAlignment;

  CycleRegimeResult({
    required this.dominantRegime,
    required this.regimeScore,
    required this.regimeAlignment,
  });
}

extension StrategyRegimeAdapter on StrategyRegimeAnalyzer {
  static CycleRegimeResult computeCycleRegime({
    required List<Map<String, dynamic>> executions,
    required String? currentRegime,
  }) {
    // Simple adapter: use currentRegime as dominant, score/align placeholders
    return CycleRegimeResult(
      dominantRegime: currentRegime,
      regimeScore: 0.0,
      regimeAlignment: 0.0,
    );
  }
}
