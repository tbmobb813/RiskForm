import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final DateTime createdAt;
  final String strategyId;
  final String? planId;
  final String? positionId;
  final String cycleState; // planned, opened, closed
  final String? notes;
  final List<String> tags;
  final int? disciplineScore;

  JournalEntry({
    required this.id,
    required this.createdAt,
    required this.strategyId,
    this.planId,
    this.positionId,
    required this.cycleState,
    this.notes,
    this.tags = const [],
    this.disciplineScore,
  });

  factory JournalEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final ts = data['createdAt'];
    DateTime created = DateTime.now();
    if (ts is Timestamp) created = ts.toDate();

    return JournalEntry(
      id: doc.id,
      createdAt: created,
      strategyId: data['strategyId'] as String? ?? 'unknown',
      planId: data['planId'] as String?,
      positionId: data['positionId'] as String?,
      cycleState: data['cycleState'] as String? ?? 'planned',
      notes: data['notes'] as String?,
      tags: List<String>.from(data['tags'] ?? <String>[]),
      disciplineScore: data['disciplineScore'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'createdAt': Timestamp.fromDate(createdAt),
        'strategyId': strategyId,
        'planId': planId,
        'positionId': positionId,
        'cycleState': cycleState,
        'notes': notes,
        'tags': tags,
        'disciplineScore': disciplineScore,
      };
}
