import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase/auth_service.dart';
import '../../state/best_opp_notifier.dart';
import 'widgets/opp_card.dart';
import 'widgets/add_opp_sheet.dart';

class BestOppsScreen extends ConsumerStatefulWidget {
  const BestOppsScreen({super.key});

  @override
  ConsumerState<BestOppsScreen> createState() => _BestOppsScreenState();
}

class _BestOppsScreenState extends ConsumerState<BestOppsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(currentUserIdProvider);
      if (uid != null) ref.read(bestOppProvider.notifier).load(uid);
    });
  }

  void _showAddSheet(String userId) {
    final state = ref.read(bestOppProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddOppSheet(
        defaultDate: state.selectedDate,
        onSave:
            ({
              required ticker,
              required setup,
              required entryTrigger,
              required whatMadeItIdeal,
              required wasTaken,
              screenshotUrl,
              notes,
            }) {
              ref
                  .read(bestOppProvider.notifier)
                  .addOpp(
                    userId: userId,
                    ticker: ticker,
                    setup: setup,
                    entryTrigger: entryTrigger,
                    whatMadeItIdeal: whatMadeItIdeal,
                    wasTaken: wasTaken,
                    screenshotUrl: screenshotUrl,
                    notes: notes,
                  );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);
    final state = ref.watch(bestOppProvider);
    final notifier = ref.read(bestOppProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Best Opps'),
        actions: [
          // Show all / by date toggle
          TextButton(
            onPressed: uid == null ? null : () => notifier.toggleShowAll(uid),
            child: Text(
              state.showAll ? 'By Date' : 'All',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (uid != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Log Opp',
              onPressed: () => _showAddSheet(uid),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to track your best opps.'))
          : Column(
              children: [
                // ── Date nav (hidden when showing all) ──────────────
                if (!state.showAll) _DateNav(uid: uid),

                // ── Stats strip ──────────────────────────────────────
                if (state.opps.isNotEmpty) _StatsStrip(opps: state.opps),

                // ── Content ──────────────────────────────────────────
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.opps.isEmpty
                      ? _EmptyState(
                          showAll: state.showAll,
                          onAdd: () => _showAddSheet(uid),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: state.opps.length,
                          itemBuilder: (context, i) {
                            final opp = state.opps[i];
                            return OppCard(
                              opp: opp,
                              onToggleTaken: () =>
                                  notifier.toggleTaken(uid, opp),
                              onDelete: () => notifier.delete(uid, opp.id),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddSheet(uid),
              tooltip: 'Log Opp',
              child: const Icon(Icons.add),
            ),
    );
  }
}

// ── Date navigation bar ────────────────────────────────────────────────────────

class _DateNav extends ConsumerWidget {
  final String uid;
  const _DateNav({required this.uid});

  String _label(String date) {
    try {
      final dt = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == today) return 'Today';
      if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month]} ${dt.day}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bestOppProvider);
    final notifier = ref.read(bestOppProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => notifier.stepDate(uid, -1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),
          Text(
            _label(state.selectedDate),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => notifier.stepDate(uid, 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ── Stats strip ────────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final List opps;
  const _StatsStrip({required this.opps});

  @override
  Widget build(BuildContext context) {
    final total = opps.length;
    final taken = opps.where((o) => o.wasTaken == true).length;
    final missed = total - taken;
    final pct = total > 0 ? (taken / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Opps', value: '$total'),
          _Stat(label: 'Taken', value: '$taken', color: Colors.green.shade400),
          _Stat(label: 'Missed', value: '$missed', color: Colors.grey),
          _Stat(
            label: 'Execution %',
            value: '$pct%',
            color: pct >= 70
                ? Colors.green.shade400
                : pct >= 40
                ? Colors.orange
                : Colors.red.shade400,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
        ),
      ),
    ],
  );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool showAll;
  final VoidCallback onAdd;
  const _EmptyState({required this.showAll, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
          ),
          const SizedBox(height: 16),
          Text(
            showAll
                ? 'No best opps logged yet.'
                : 'No opps logged for this day.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log Your First Opp'),
          ),
        ],
      ),
    ),
  );
}
