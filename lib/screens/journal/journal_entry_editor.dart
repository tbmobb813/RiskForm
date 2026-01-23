import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/journal/journal_entry.dart';
import '../../state/journal_providers.dart';

class JournalEntryEditor extends ConsumerStatefulWidget {
  final JournalEntry? existing;

  const JournalEntryEditor({super.key, this.existing});

  @override
  ConsumerState<JournalEntryEditor> createState() => _JournalEntryEditorState();
}

class _JournalEntryEditorState extends ConsumerState<JournalEntryEditor> {
  late TextEditingController _notesController;
  late TextEditingController _tagsController;
  late TextEditingController _screenshotController;
  List<String> _screenshots = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final notes = (e?.data['notes'] as String?) ?? '';
    final tags = (e?.data['tags'] as List<dynamic>?)?.map((t) => t.toString()).join(', ') ?? '';
    final shots = (e?.data['screenshots'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [];
    _screenshots = shots;
    _notesController = TextEditingController(text: notes);
    _tagsController = TextEditingController(text: tags);
    _screenshotController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tagsController.dispose();
    _screenshotController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notes = _notesController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final repo = ref.read(journalRepositoryProvider);
    if (widget.existing != null) {
      final existing = widget.existing!;
      final updated = JournalEntry(
        id: existing.id,
        timestamp: existing.timestamp,
        type: existing.type,
        data: {
          ...existing.data,
          'notes': notes,
          'tags': tags,
          'screenshots': _screenshots,
          'live': existing.data['live'] ?? false,
        },
      );
      await repo.updateEntry(updated);
    } else {
      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: 'note',
        data: {
          'notes': notes,
          'tags': tags,
          'screenshots': _screenshots,
          'live': false,
        },
      );
      await repo.addEntry(entry);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  void _addScreenshot() {
    final val = _screenshotController.text.trim();
    if (val.isEmpty) return;
    setState(() {
      _screenshots.add(val);
      _screenshotController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Journal Entry' : 'Edit Journal Entry'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write notes about this strategy...',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _screenshotController,
                    decoration: const InputDecoration(
                      labelText: 'Screenshot URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addScreenshot, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 8),
            if (_screenshots.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _screenshots.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final url = _screenshots[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 120, child: Text(url, overflow: TextOverflow.ellipsis)),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => setState(() => _screenshots.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
