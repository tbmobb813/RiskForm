import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/create_test_data.dart';
import '../controllers/cockpit_controller.dart';
import '../models/pending_journal_trade.dart';

/// Debug screen for testing the Small Account Cockpit
///
/// Navigate to this screen to:
/// - Create test journal data
/// - Add/remove pending journals
/// - Navigate to cockpit
/// - View current cockpit state
///
/// Add to router:
/// ```dart
/// GoRoute(
///   path: '/debug/cockpit',
///   name: 'cockpit_debug',
///   builder: (context, state) => const CockpitDebugScreen(),
/// ),
/// ```
class CockpitDebugScreen extends ConsumerWidget {
  const CockpitDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cockpitControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cockpit Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cockpitControllerProvider.notifier).refresh(),
            tooltip: 'Refresh cockpit data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation
            _buildSection(
              context,
              'Navigation',
              [
                _buildButton(
                  context,
                  'Open Cockpit',
                  Icons.speed,
                  () => context.goNamed('cockpit'),
                ),
                _buildButton(
                  context,
                  'Open Behavior Dashboard',
                  Icons.psychology,
                  () => context.goNamed('behavior'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Test Data Creation
            _buildSection(
              context,
              'Test Data Creation',
              [
                _buildButton(
                  context,
                  'Create All Test Data',
                  Icons.add_box,
                  () => _createAllTestData(context),
                ),
                _buildButton(
                  context,
                  'Create Journal Entries',
                  Icons.book,
                  () => _createJournals(context),
                ),
                _buildButton(
                  context,
                  'Create Test Watchlist',
                  Icons.list,
                  () => _createWatchlist(context),
                ),
                _buildButton(
                  context,
                  'Clear All Test Data',
                  Icons.delete_forever,
                  () => _clearTestData(context),
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pending Journal Testing
            _buildSection(
              context,
              'Pending Journal Testing',
              [
                _buildButton(
                  context,
                  'Add Test Pending Journal',
                  Icons.warning,
                  () => _addPendingJournal(context, ref),
                  color: Colors.orange,
                ),
                _buildButton(
                  context,
                  'Clear Pending Journals',
                  Icons.check_circle,
                  () => _clearPendingJournals(context, ref),
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Current State
            _buildSection(
              context,
              'Current Cockpit State',
              [
                _buildStatCard('Discipline Score', '${state.discipline.currentScore}/100'),
                _buildStatCard('Clean Streak', '${state.discipline.cleanStreak} days'),
                _buildStatCard('Adherence Streak', '${state.discipline.adherenceStreak} days'),
                _buildStatCard('Discipline Level', state.discipline.level.label),
                _buildStatCard('Pending Journals', '${state.pendingJournals.length}'),
                _buildStatCard('Is Blocked', state.isBlocked ? 'YES' : 'NO'),
                _buildStatCard('Watchlist', '${state.watchlist.length}/5'),
                _buildStatCard('Open Positions', '${state.positions.length}'),
                _buildStatCard('Weekly Trades', '${state.weekSummary.trades}'),
                _buildStatCard('Regime', state.regime.displayName),
              ],
            ),

            const SizedBox(height: 24),

            // Status Message
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Message',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(state.discipline.statusMessage),
                  ],
                ),
              ),
            ),

            if (state.blockingMessage != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.block, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Blocking Message',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(state.blockingMessage!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: child,
            )),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color != null ? Colors.white : null,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAllTestData(BuildContext context) async {
    try {
      await CockpitTestData.createAllTestData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All test data created! Navigate to cockpit to see it.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createJournals(BuildContext context) async {
    try {
      await CockpitTestData.createTestJournals();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Created test journal entries')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createWatchlist(BuildContext context) async {
    try {
      await CockpitTestData.createTestWatchlist();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Created test watchlist')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearTestData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Test Data?'),
        content: const Text('This will delete all journal entries and cockpit data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await CockpitTestData.clearAllTestData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Cleared all test data')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _addPendingJournal(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(cockpitControllerProvider.notifier).addPendingJournal(
            PendingJournalTrade(
              positionId: 'test-${DateTime.now().millisecondsSinceEpoch}',
              ticker: 'AAPL',
              strategy: 'CSP AAPL \$170',
              pnl: 42.50,
              closedAt: DateTime.now(),
              isPaper: true,
            ),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Added pending journal. Try opening cockpit and clicking "New Trade Plan"'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearPendingJournals(BuildContext context, WidgetRef ref) async {
    try {
      final state = ref.read(cockpitControllerProvider);
      for (final journal in state.pendingJournals) {
        await ref.read(cockpitControllerProvider.notifier).removePendingJournal(journal.positionId);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cleared all pending journals')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
