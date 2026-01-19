import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'behavior_analytics.dart';
import '../journal/journal_entry_model.dart';

class BehaviorDashboardScreen extends StatelessWidget {
  const BehaviorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('journalEntries')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Behavior Dashboard')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No journal data'));

          final entries = snap.data!.docs.map((d) => JournalEntry.fromFirestore(d)).toList();

          final trend = BehaviorAnalytics.computeTrendline(entries);
          final cleanStreak = BehaviorAnalytics.computeCleanCycleStreak(entries);
          final adherenceStreak = BehaviorAnalytics.computeAdherenceStreak(entries);
          final lastFive = entries.take(5).toList();
          final avg5 = BehaviorAnalytics.averageLastFive(lastFive);
          final mostCommon = BehaviorAnalytics.mostCommonViolation(lastFive);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Discipline Trend (last 30)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(height: 60, child: _Sparkline(values: trend)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _StatCard(title: 'Clean Cycles', value: '$cleanStreak'),
                      const SizedBox(width: 12),
                      _StatCard(title: 'Adherence Streak', value: '$adherenceStreak'),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text('Last 5 Trades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Avg Score: ${avg5.toStringAsFixed(0)}'),
                        const SizedBox(height: 6),
                        Text('Most Common Violation: ${_friendlyViolationName(mostCommon)}'),
                        const SizedBox(height: 8),
                        Column(
                          children: lastFive.map((e) => ListTile(
                                dense: true,
                                title: Text('Score: ${e.disciplineScore ?? 0}'),
                                subtitle: Text(e.strategyId),
                                trailing: Text((e.createdAt.toLocal().toString().split('.').first)),
                              )).toList(),
                        )
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Next Best Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(_nextBestAction(lastFive)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _nextBestAction(List<JournalEntry> lastFive) {
    if (lastFive.isEmpty) return 'No recent trades to suggest an action.';
    final violation = BehaviorAnalytics.mostCommonViolation(lastFive);
    switch (violation) {
      case 'timing':
        return 'Focus on timing consistency this week.';
      case 'adherence':
        return 'Keep sizing and strikes consistent to maintain adherence.';
      case 'risk':
        return 'Check position sizing and stop-loss alignment to reduce risk.';
      default:
        return 'Keep doing what you are doing — review recent trades for details.';
    }
  }

  String _friendlyViolationName(String key) {
    switch (key) {
      case 'timing':
        return 'Timing';
      case 'adherence':
        return 'Adherence';
      case 'risk':
        return 'Risk';
      default:
        return 'None';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  const _Sparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1 : (max - min);

              return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values.map((v) {
        final t = (v - min) / range;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: Container(
              height: 60 * t + 4,
              decoration: BoxDecoration(
                color: Colors.green.withAlpha((0.7 * 255).round()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
