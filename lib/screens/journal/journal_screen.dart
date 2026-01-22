import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journal/journal_entry.dart';
import '../../state/journal_providers.dart';
import 'journal_entry_editor.dart';
import '../../state/discipline_providers.dart';
import '../../services/journal/journal_repository.dart';
import 'components/discipline_score_card.dart';
import '../../services/journal/discipline_history_service.dart';
import 'components/discipline_history_card.dart';
import '../../services/journal/discipline_timeline_service.dart';
import 'components/discipline_streaks_card.dart';
import 'components/habit_stats_card.dart';
import 'journal_entry_detail.dart';
import 'journal_filter_bar.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String filter = 'all';
  JournalRepository? _repo;

  @override
  void initState() {
    super.initState();
    // Attach listener to repository so UI updates when entries change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = ref.read(journalRepositoryProvider);
      _repo = r;
      try {
        _repo?.addListener(_onRepoChanged);
      } catch (_) {}
    });
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    try {
      _repo?.removeListener(_onRepoChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(journalRepositoryProvider);
    final allEntries = repo.getAll();
    var entries = allEntries.reversed.toList(); // newest first

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

    final scoring = ref.read(disciplineScoringProvider);
    final score = scoring.compute(allEntries);

    final historyService = DisciplineHistoryService(scorer: scoring);
    final history = historyService.computeHistory(allEntries, days: 30);

    final timelineService = DisciplineTimelineService(scoring: scoring);
    final timeline = timelineService.buildTimeline(allEntries);
    final streaks = timelineService.computeStreaks(timeline);
    final habits = timelineService.computeHabits(allEntries);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalEntryEditor()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DisciplineScoreCard(score: score),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DisciplineHistoryCard(history: history),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DisciplineStreaksCard(streaks: streaks),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HabitStatsCard(habits: habits),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: JournalFilterBar(
              selectedType: filter,
              onChanged: (t) => setState(() => filter = t),
            ),
          ),
          // Groups of journal entries
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groups
                  .map((group) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              group.key,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...group.value.map((e) => _JournalListTile(key: ValueKey(e.id), entry: e)),
                        ],
                      ))
                  .toList(),
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
      child: Semantics(
        container: true,
        label: 'entry-${entry.id}',
        child: ListTile(
          key: ValueKey('entry-${entry.id}'),
          title: Text(_titleFor(entry)),
        subtitle: Text(
          '${entry.timestamp.toLocal()}${_isLive(entry) ? " • LIVE" : ""}',
          style: const TextStyle(fontSize: 12),
        ),
        tileColor: _isLive(entry) ? Colors.blueGrey.shade50 : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JournalEntryDetail(entry: entry)),
          );
        },
        ),
      ),
    );
  }

  bool _isLive(JournalEntry e) => e.data['live'] == true;

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
