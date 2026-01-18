class DailyDisciplineSnapshot {
  final DateTime date;
  final double score; // 0–100
  final int cyclesCompleted;
  final int assignments;
  final int calledAway;

  DailyDisciplineSnapshot({
    required this.date,
    required this.score,
    required this.cyclesCompleted,
    required this.assignments,
    required this.calledAway,
  });
}
