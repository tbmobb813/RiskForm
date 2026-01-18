import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journal/journal_entry.dart';
import '../../state/journal_providers.dart';
import 'journal_entry_detail.dart';
import 'journal_filter_bar.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(journalRepositoryProvider);
    var entries = repo.getAll().reversed.toList(); // newest first

    if (filter != 'all') {
      entries = entries.where((e) => e.type == filter).toList();
    }

    // group by date string
    final Map<String, List<JournalEntry>> grouped = {};
    for (final e in entries) {
      final key = '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}-${e.timestamp.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final groups = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: JournalFilterBar(
              selectedType: filter,
              onChanged: (t) => setState(() => filter = t),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: groups.length,
              itemBuilder: (context, gi) {
                final group = groups[gi];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        group.key,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...group.value.map((e) => _JournalListTile(entry: e)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalListTile extends StatelessWidget {
  final JournalEntry entry;

  const _JournalListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(_titleFor(entry)),
        subtitle: Text(
          '${entry.timestamp.toLocal()}',
          style: const TextStyle(fontSize: 12),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JournalEntryDetail(entry: entry)),
          );
        },
      ),
    );
  }

  String _titleFor(JournalEntry e) {
    switch (e.type) {
      case 'cycle':
        final idx = e.data['cycleIndex']?.toString() ?? '?';
        final r = (e.data['cycleReturn'] is double) ? (e.data['cycleReturn'] * 100).toStringAsFixed(2) + '%' : '';
        return 'Cycle $idx ${r.isNotEmpty ? '— $r' : ''}';
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
