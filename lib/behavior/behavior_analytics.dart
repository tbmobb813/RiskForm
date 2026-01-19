import '../journal/journal_entry_model.dart';

class BehaviorAnalytics {
  /// Returns trendline values with oldest first.
  static List<double> computeTrendline(List<JournalEntry> entries) {
    return entries
        .map((e) => (e.disciplineScore ?? 0).toDouble())
        .toList()
        .reversed
        .toList();
  }

  /// Count of consecutive entries from newest -> oldest where total score >= 80.
  static int computeCleanCycleStreak(List<JournalEntry> entries) {
    int streak = 0;
    for (final e in entries) {
      if (e.disciplineScore != null && e.disciplineScore! >= 80) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Count of consecutive entries where adherence component >= 30.
  static int computeAdherenceStreak(List<JournalEntry> entries) {
    int streak = 0;
    for (final e in entries) {
      final breakdown = e.disciplineBreakdown;
      if (breakdown != null && (breakdown['adherence'] ?? 0) >= 30) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static double averageLastFive(List<JournalEntry> entries) {
    final lastFive = entries.take(5).toList();
    if (lastFive.isEmpty) return 0;
    final sum = lastFive.map((e) => e.disciplineScore ?? 0).reduce((a, b) => a + b);
    return sum / lastFive.length;
  }

  /// Determine most common lowest-scoring component across entries.
  static String mostCommonViolation(List<JournalEntry> entries) {
    final counts = <String, int>{'adherence': 0, 'timing': 0, 'risk': 0};
    for (final e in entries) {
      final b = e.disciplineBreakdown;
      if (b == null) continue;
      final adherence = (b['adherence'] ?? 0) as num;
      final timing = (b['timing'] ?? 0) as num;
      final risk = (b['risk'] ?? 0) as num;
      final minVal = [adherence, timing, risk].reduce((a, b) => a < b ? a : b);
      if (minVal == adherence) {
        counts['adherence'] = counts['adherence']! + 1;
      } else if (minVal == timing) counts['timing'] = counts['timing']! + 1;
      else counts['risk'] = counts['risk']! + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.isNotEmpty ? sorted.first.key : 'none';
  }
}
