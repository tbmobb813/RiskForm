class StrategyCycleRegime {
  final String? dominantRegime;
  final double regimeScore;      // 0–100, how well it fits the regime
  final double regimeAlignment;  // -1 to +1, negative = fights regime

  const StrategyCycleRegime({
    required this.dominantRegime,
    required this.regimeScore,
    required this.regimeAlignment,
  });
}

class StrategyRegimeAnalyzer {
  /// executions: trade summaries
  /// currentRegime: from StrategyHealth / context ("uptrend", "downtrend", "sideways", etc.)
  static StrategyCycleRegime computeCycleRegime({
    required List<Map<String, dynamic>> executions,
    required String? currentRegime,
  }) {
    if (executions.isEmpty) {
      return const StrategyCycleRegime(
        dominantRegime: null,
        regimeScore: 0,
        regimeAlignment: 0,
      );
    }

    // For now, treat currentRegime as dominantRegime.
    final dominant = currentRegime;

    // Simple heuristic: if most trades are aligned with regime direction, score higher.
    int aligned = 0;
    int counter = 0;

    for (final e in executions) {
      final type = (e['type'] ?? '').toString().toUpperCase();

      // You can plug in real regime logic later; for now:
      // - In uptrend: selling puts / covered calls = aligned
      // - In downtrend: buying puts / selling calls = aligned
      if (dominant == 'uptrend') {
        if (type.contains('SELL_PUT') || type.contains('COVERED_CALL')) {
          aligned++;
        } else {
          counter++;
        }
      } else if (dominant == 'downtrend') {
        if (type.contains('BUY_PUT') || type.contains('SELL_CALL')) {
          aligned++;
        } else {
          counter++;
        }
      } else {
        // sideways or unknown: neutral
      }
    }

    final total = aligned + counter;
    double alignment = 0;
    if (total > 0) {
      alignment = (aligned - counter) / total; // -1 to +1
    }

    // Regime score: map alignment to 0–100
    final regimeScore = ((alignment + 1) / 2) * 100;

    return StrategyCycleRegime(
      dominantRegime: dominant,
      regimeScore: regimeScore,
      regimeAlignment: alignment,
    );
  }
}
