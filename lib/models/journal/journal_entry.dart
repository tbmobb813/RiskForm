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
