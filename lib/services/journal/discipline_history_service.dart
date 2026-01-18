import '../../models/journal/journal_entry.dart';
import '../../models/journal/daily_discipline.dart';
import 'discipline_scoring_service.dart';

class DisciplineHistoryService {
  final DisciplineScoringService scorer;

  DisciplineHistoryService({required this.scorer});

  /// Compute daily discipline scores for the past [days] (including today).
  List<DailyDiscipline> computeHistory(List<JournalEntry> entries, {int days = 30}) {
    final now = DateTime.now();
    final List<DailyDiscipline> out = [];

    for (var i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayEntries = entries.where((e) => e.timestamp.isAfter(dayStart.subtract(const Duration(microseconds: 1))) && e.timestamp.isBefore(dayEnd)).toList();
      final score = scorer.compute(dayEntries);
      out.add(DailyDiscipline(date: dayStart, score: score));
    }

    return out.reversed.toList(); // oldest → newest
  }

  /// Current streak of days meeting threshold (most recent consecutive days ≥ threshold).
  int computeStreak(List<DailyDiscipline> history, {double threshold = 70.0}) {
    int streak = 0;
    for (var i = history.length - 1; i >= 0; i--) {
      final s = history[i].score.score;
      if (s >= threshold) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  double average(List<DailyDiscipline> history, {int lastN = 7}) {
    if (history.isEmpty) return 0.0;
    final slice = history.sublist(history.length - lastN < 0 ? 0 : history.length - lastN);
    final sum = slice.fold<double>(0.0, (a, d) => a + d.score.score);
    return sum / slice.length;
  }
}
