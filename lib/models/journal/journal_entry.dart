import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final DateTime timestamp;
  final String type; // "cycle", "assignment", "calledAway", "backtest", "note", "selection"
  final Map<String, dynamic> data;

  JournalEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.data,
  });

  /// Convenience getters for common journaling fields stored inside `data`.
  String? get notes => data['notes'] as String?;

  List<String>? get tags => (data['tags'] is List) ? List<String>.from(data['tags'] ?? []) : null;

  List<Map<String, dynamic>>? get attachments => (data['attachments'] is List)
      ? List<Map<String, dynamic>>.from(data['attachments'] ?? [])
      : null;

  JournalEntry copyWith({String? id, DateTime? timestamp, String? type, Map<String, dynamic>? data}) {
    return JournalEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      data: data ?? Map<String, dynamic>.from(this.data),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'data': data,
    };
  }

  static JournalEntry fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final type = d['type'] as String? ?? 'note';
    final data = Map<String, dynamic>.from(d['data'] ?? {});
    return JournalEntry(
      id: doc.id,
      timestamp: ts,
      type: type,
      data: data,
    );
  }
}
