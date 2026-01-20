import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/journal/journal_repository.dart';
import 'package:riskform/models/journal/journal_entry.dart';

void main() {
  test('JournalRepository add and getAll', () async {
    final repo = JournalRepository();
    final entry = JournalEntry(
      id: 'e1',
      timestamp: DateTime(2025, 1, 1),
      type: 'cycle',
      data: {'cycleIndex': 0},
    );

    await repo.addEntry(entry);

    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.id, 'e1');
  });
}
