import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/journal/discipline_timeline_service.dart';
import 'package:flutter_application_2/services/journal/discipline_scoring_service.dart';
import 'package:flutter_application_2/models/journal/daily_discipline_snapshot.dart';
import 'package:flutter_application_2/models/journal/journal_entry.dart';

void main() {
  group('DisciplineTimelineService', () {
    test('buildTimeline groups entries by day and counts events', () {
      final scorer = DisciplineScoringService();
      final svc = DisciplineTimelineService(scoring: scorer);

      final day1 = DateTime(2025, 1, 1);
      final day2 = DateTime(2025, 1, 2);

      final entries = [
        JournalEntry(id: 'c1', timestamp: day1.add(const Duration(hours: 9)), type: 'cycle', data: {}),
        JournalEntry(id: 'a1', timestamp: day1.add(const Duration(hours: 10)), type: 'assignment', data: {}),
        JournalEntry(id: 'c2', timestamp: day2.add(const Duration(hours: 11)), type: 'cycle', data: {}),
        JournalEntry(id: 'c3', timestamp: day2.add(const Duration(hours: 12)), type: 'cycle', data: {}),
        JournalEntry(id: 'ca1', timestamp: day2.add(const Duration(hours: 13)), type: 'calledAway', data: {}),
      ];

      final timeline = svc.buildTimeline(entries);

      expect(timeline.length, 2);

      final snap1 = timeline.firstWhere((s) => s.date == DateTime(2025, 1, 1));
      expect(snap1.cyclesCompleted, 1);
      expect(snap1.assignments, 1);
      expect(snap1.calledAway, 0);

      final snap2 = timeline.firstWhere((s) => s.date == DateTime(2025, 1, 2));
      expect(snap2.cyclesCompleted, 2);
      expect(snap2.assignments, 0);
      expect(snap2.calledAway, 1);
    });

    test('computeStreaks calculates discipline, clean cycle, and no-assignment streaks', () {
      final scorer = DisciplineScoringService();
      final svc = DisciplineTimelineService(scoring: scorer);

      // create timeline snapshots (oldest -> newest)
      final List<DailyDisciplineSnapshot> timeline = [
        // older day: low score, had assignment
        DailyDisciplineSnapshot(date: DateTime(2025, 1, 1), score: 50.0, cyclesCompleted: 1, assignments: 1, calledAway: 0),
        // middle day: high score, clean
        DailyDisciplineSnapshot(date: DateTime(2025, 1, 2), score: 80.0, cyclesCompleted: 1, assignments: 0, calledAway: 0),
        // newest day: high score, clean
        DailyDisciplineSnapshot(date: DateTime(2025, 1, 3), score: 85.0, cyclesCompleted: 1, assignments: 0, calledAway: 0),
      ];

      final streaks = svc.computeStreaks(timeline);

      expect(streaks.disciplineStreakDays, 2); // last two days >= 70
      expect(streaks.cleanCycleStreak, 2); // last two days had no assignments/calledAway
      expect(streaks.noAssignmentStreak, 2);
    });

    test('computeHabits computes rates from entries', () {
      final scorer = DisciplineScoringService();
      final svc = DisciplineTimelineService(scoring: scorer);

      final entries = [
        JournalEntry(id: 'c1', timestamp: DateTime(2025, 1, 1), type: 'cycle', data: {'hadAssignment': false}),
        JournalEntry(id: 'c2', timestamp: DateTime(2025, 1, 2), type: 'cycle', data: {'hadAssignment': true}),
        JournalEntry(id: 'a1', timestamp: DateTime(2025, 1, 2), type: 'assignment', data: {}),
        JournalEntry(id: 'ca1', timestamp: DateTime(2025, 1, 2), type: 'calledAway', data: {}),
      ];

      final habits = svc.computeHabits(entries);

      // Two cycles, one clean -> cleanCycleRate = 0.5
      expect(habits.cleanCycleRate, closeTo(0.5, 1e-9));

      // assignments =1, cycles=2 -> assignmentAvoidanceRate = 1 - 1/2 = 0.5
      expect(habits.assignmentAvoidanceRate, closeTo(0.5, 1e-9));

      // calledAway =1, cycles=2 -> planAdherenceRate = 1/2 = 0.5
      expect(habits.planAdherenceRate, closeTo(0.5, 1e-9));
    });
  });
}
