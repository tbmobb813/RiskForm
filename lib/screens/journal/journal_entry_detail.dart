import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/journal/journal_entry.dart';
import '../../state/journal_providers.dart';
import 'journal_entry_editor.dart';

class JournalEntryDetail extends ConsumerStatefulWidget {
  final JournalEntry entry;

  const JournalEntryDetail({super.key, required this.entry});

  @override
  ConsumerState<JournalEntryDetail> createState() => _JournalEntryDetailState();
}

class _JournalEntryDetailState extends ConsumerState<JournalEntryDetail> {
  late JournalEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _refresh() async {
    final repo = ref.read(journalRepositoryProvider);
    final latest = await repo.getById(_entry.id);
    if (latest != null) {
      setState(() {
        _entry = latest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(_entry)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete entry'),
                  content: const Text('Are you sure you want to delete this journal entry? This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                if (!mounted) return;
                final repo = ref.read(journalRepositoryProvider);

                // Capture deleted entry so we can restore on undo.
                final deleted = _entry;

                // Capture a messenger scoped to the previous screen so SnackBar survives pop.
                final messenger = ScaffoldMessenger.of(navigator.context);

                await repo.deleteEntry(_entry.id);

                // Show undo SnackBar on parent scaffold. Restore if user taps Undo.
                messenger.showSnackBar(SnackBar(
                  content: const Text('Journal entry deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () async {
                      await repo.addEntry(deleted);
                    },
                  ),
                  duration: const Duration(seconds: 6),
                ));

                if (!mounted) return;
                navigator.pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JournalEntryEditor(existing: _entry)),
              );
              if (res == true) {
                await _refresh();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timestamp: ${_entry.timestamp.toLocal()}'),
            const SizedBox(height: 16),
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._entry.data.entries.map(
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
