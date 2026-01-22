import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String userId;
  final String strategyId;
  final String strategyName;
  final String? strategySymbol;
  final String? description;
  final String notes;
  final List<String> tags;
  final List<String> screenshots;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.strategyId,
    required this.strategyName,
    this.strategySymbol,
    this.description,
    this.notes = '',
    this.tags = const [],
    this.screenshots = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'strategyId': strategyId,
      'strategyName': strategyName,
      'strategySymbol': strategySymbol,
      'description': description,
      'notes': notes,
      'tags': tags,
      'screenshots': screenshots,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static JournalEntry fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JournalEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      strategyId: data['strategyId'] ?? '',
      strategyName: data['strategyName'] ?? '',
      strategySymbol: data['strategySymbol'] as String?,
      description: data['description'] as String?,
      notes: data['notes'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      screenshots: List<String>.from(data['screenshots'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
