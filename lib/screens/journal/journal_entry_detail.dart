import 'package:flutter/material.dart';
import '../../models/journal/journal_entry.dart';

class JournalEntryDetail extends StatelessWidget {
  final JournalEntry entry;

  const JournalEntryDetail({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(entry)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timestamp: ${entry.timestamp.toLocal()}'),
            const SizedBox(height: 16),
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...entry.data.entries.map(
              (kv) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${kv.key}: ${kv.value}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(JournalEntry e) {
    switch (e.type) {
      case 'cycle':
        return 'Cycle ${e.data['cycleIndex'] ?? ''}';
      case 'assignment':
        return 'Assignment Event';
      case 'calledAway':
        return 'Called Away Event';
      case 'backtest':
        return 'Backtest Summary';
      default:
        return 'Journal Entry';
    }
  }
}
