import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JournalDetailScreen extends StatefulWidget {
  final String entryId;

  const JournalDetailScreen({super.key, required this.entryId});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  late final DocumentReference<Map<String, dynamic>> _ref;

  @override
  void initState() {
    super.initState();
    _ref = FirebaseFirestore.instance.collection('journalEntries').doc(widget.entryId);
  }

  Future<void> _editNotes(String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (result != null) {
      await _ref.update({'notes': result});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved')));
    }
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'tag')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await _ref.update({
        'tags': FieldValue.arrayUnion([result.trim()])
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tag added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal Entry')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Entry not found'));
          }

          final data = snapshot.data!.data()!;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate()?.toLocal()?.toString()?.split('.')?.first ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Strategy: ${data['strategyId'] ?? 'unknown'}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('State: ${data['cycleState'] ?? 'unknown'}'),
                  const SizedBox(height: 8),
                  Text('Created: $createdAt'),
                  const Divider(height: 24),
                  Text('Notes', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(data['notes'] as String? ?? '—'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: (List<String>.from(data['tags'] ?? <String>[]))
                        .map((t) => Chip(label: Text(t)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  if (data['disciplineScore'] != null) ...[
                    Text('Discipline score: ${data['disciplineScore']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (data['disciplineBreakdown'] != null)
                      Builder(builder: (context) {
                        final breakdown = Map<String, dynamic>.from(data['disciplineBreakdown'] ?? <String, dynamic>{});
                        final adherence = breakdown['adherence'] ?? 0;
                        final timing = breakdown['timing'] ?? 0;
                        final risk = breakdown['risk'] ?? 0;
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Adherence: $adherence/40'),
                                const SizedBox(height: 6),
                                Text('Timing: $timing/30'),
                                const SizedBox(height: 6),
                                Text('Risk: $risk/30'),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      ElevatedButton(onPressed: () => _editNotes(data['notes'] as String?), child: const Text('Edit Notes')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _addTag, child: const Text('Add Tag')),
                      const SizedBox(width: 8),
                      if (data['planId'] != null)
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open plan (not implemented)')));
                          },
                          child: const Text('View Plan'),
                        ),
                      const SizedBox(width: 8),
                      if (data['positionId'] != null)
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open position (not implemented)')));
                          },
                          child: const Text('View Position'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
