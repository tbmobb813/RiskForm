class JournalEntry {
  final String id;
  final DateTime timestamp;
  final String type; // "cycle", "assignment", "calledAway", "backtest"
  final Map<String, dynamic> data;

  JournalEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.data,
  });
}
