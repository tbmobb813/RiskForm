import '../../models/journal/journal_entry.dart';

class JournalRepository {
  final List<JournalEntry> _entries = [];

  Future<void> addEntry(JournalEntry entry) async {
    _entries.add(entry);
  }

  List<JournalEntry> getAll() => List.unmodifiable(_entries);
}
