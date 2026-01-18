import '../../models/journal/journal_entry.dart';
import '../../models/journal/daily_discipline_snapshot.dart';
import 'discipline_scoring_service.dart';

class DisciplineStreaks {
  final int disciplineStreakDays;
  final int cleanCycleStreak;
  final int noAssignmentStreak;

  DisciplineStreaks({
    required this.disciplineStreakDays,
    required this.cleanCycleStreak,
    required this.noAssignmentStreak,
  });
}

class HabitStats {
  final double cleanCycleRate;
  final double assignmentAvoidanceRate;
  final double planAdherenceRate;

  HabitStats({
    required this.cleanCycleRate,
    required this.assignmentAvoidanceRate,
    required this.planAdherenceRate,
  });
}

class DisciplineTimelineService {
  final DisciplineScoringService scoring;

  DisciplineTimelineService({required this.scoring});

  List<DailyDisciplineSnapshot> buildTimeline(List<JournalEntry> entries) {
    if (entries.isEmpty) return [];

    final Map<DateTime, List<JournalEntry>> byDay = {};

    for (final e in entries) {
      final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      byDay.putIfAbsent(day, () => []).add(e);
    }

    final snapshots = <DailyDisciplineSnapshot>[];

    final days = byDay.keys.toList()..sort();
    for (final day in days) {
      final dayEntries = byDay[day]!;
      final score = scoring.compute(dayEntries);

      snapshots.add(DailyDisciplineSnapshot(
        date: day,
        score: score.score,
        cyclesCompleted: dayEntries.where((e) => e.type == 'cycle').length,
        assignments: dayEntries.where((e) => e.type == 'assignment').length,
        calledAway: dayEntries.where((e) => e.type == 'calledAway').length,
      ));
    }

    return snapshots;
  }

  DisciplineStreaks computeStreaks(List<DailyDisciplineSnapshot> timeline) {
    if (timeline.isEmpty) {
      return DisciplineStreaks(
        disciplineStreakDays: 0,
        cleanCycleStreak: 0,
        noAssignmentStreak: 0,
      );
    }

    int disciplineStreak = 0;
    int cleanCycleStreak = 0;
    int noAssignmentStreak = 0;

    const threshold = 70.0;

    for (final day in timeline.reversed) {
      if (day.score >= threshold) {
        disciplineStreak += 1;
      } else {
        break;
      }
    }

    for (final day in timeline.reversed) {
      if (day.assignments == 0 && day.calledAway == 0) {
        cleanCycleStreak += 1;
      } else {
        break;
      }
    }

    for (final day in timeline.reversed) {
      if (day.assignments == 0) {
        noAssignmentStreak += 1;
      } else {
        break;
      }
    }

    return DisciplineStreaks(
      disciplineStreakDays: disciplineStreak,
      cleanCycleStreak: cleanCycleStreak,
      noAssignmentStreak: noAssignmentStreak,
    );
  }

  HabitStats computeHabits(List<JournalEntry> entries) {
    final cycles = entries.where((e) => e.type == 'cycle').toList();
    final assignments = entries.where((e) => e.type == 'assignment').length;
    final calledAway = entries.where((e) => e.type == 'calledAway').length;

    final cleanCycles = cycles.where((e) {
      final hadAssignment = e.data['hadAssignment'] == true;
      return !hadAssignment;
    }).length;

    final cleanCycleRate = cycles.isEmpty ? 0.0 : cleanCycles / cycles.length;
    final assignmentAvoidanceRate = cycles.isEmpty ? 0.0 : (1 - assignments / cycles.length);
    final planAdherenceRate = cycles.isEmpty ? 0.0 : (calledAway / cycles.length);

    return HabitStats(
      cleanCycleRate: cleanCycleRate,
      assignmentAvoidanceRate: assignmentAvoidanceRate,
      planAdherenceRate: planAdherenceRate,
    );
  }
}
