import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/cockpit_controller.dart';
import 'widgets/discipline_header_card.dart';
import 'widgets/account_snapshot_card.dart';
import 'widgets/required_action_card.dart';
import 'widgets/watchlist_card.dart';
import 'widgets/open_positions_card.dart';
import 'widgets/quick_actions_card.dart';
import 'widgets/weekly_summary_card.dart';

/// Small Account Cockpit - Unified dashboard screen
///
/// This is the main screen for small account traders, consolidating:
/// - Discipline tracking and streaks
/// - Account snapshot
/// - Behavioral friction (journal blocking)
/// - Watchlist (max 5 tickers)
/// - Open positions
/// - Quick actions
/// - Weekly performance
class SmallAccountCockpitScreen extends ConsumerWidget {
  const SmallAccountCockpitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cockpitControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Small Account Cockpit'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cockpitControllerProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(cockpitControllerProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Discipline Header (always visible, most prominent)
                    DisciplineHeaderCard(discipline: state.discipline),
                    const SizedBox(height: 16),

                    // Account Snapshot
                    AccountSnapshotCard(
                      account: state.account,
                      regime: state.regime,
                    ),
                    const SizedBox(height: 16),

                    // Required Action (only visible when blocked)
                    if (state.isBlocked) ...[
                      RequiredActionCard(
                        pendingJournals: state.pendingJournals,
                        onJournalTap: (trade) {
                          // TODO: Navigate to journal form with pre-filled data
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Journal ${trade.ticker} trade')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Watchlist
                    WatchlistCard(
                      watchlist: state.watchlist,
                      onAddTicker: () => _showAddTickerDialog(context, ref),
                      onRemoveTicker: (ticker) => ref.read(cockpitControllerProvider.notifier).removeFromWatchlist(ticker),
                      onScanTap: (ticker) {
                        // TODO: Navigate to options scanner
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Scan $ticker options (coming soon)')),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Open Positions
                    OpenPositionsCard(
                      positions: state.positions,
                      onManageTap: (position) {
                        // TODO: Navigate to position management
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Manage ${position.ticker} position')),
                        );
                      },
                      onJournalAndCloseTap: (position) {
                        // TODO: Navigate to journal form
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Journal and close ${position.ticker}')),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions
                    QuickActionsCard(
                      isBlocked: state.isBlocked,
                      onNewTradePlan: () => _handleNewTradePlan(context, state),
                      onPerformance: () {
                        // TODO: Navigate to performance screen
                      },
                      onBehavior: () {
                        // TODO: Navigate to behavior dashboard
                      },
                    ),
                    const SizedBox(height: 16),

                    // Weekly Summary
                    WeeklySummaryCard(summary: state.weekSummary),
                    const SizedBox(height: 32), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  /// Show dialog to add a ticker to watchlist
  void _showAddTickerDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Ticker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter ticker symbol (max 5 tickers for small accounts)'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., SPY',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ticker = controller.text.trim().toUpperCase();
              if (ticker.isEmpty) return;

              try {
                await ref.read(cockpitControllerProvider.notifier).addToWatchlist(ticker);
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Handle new trade plan with blocking logic
  void _handleNewTradePlan(BuildContext context, dynamic state) {
    // Check if blocked
    if (state.isBlocked) {
      _showBlockedDialog(context, state.blockingMessage);
      return;
    }

    // Check discipline warning
    if (state.shouldShowDisciplineWarning) {
      _showDisciplineWarningDialog(
        context,
        state.discipline.currentScore,
        onProceed: () {
          // TODO: Navigate to trade planner
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening trade planner...')),
          );
        },
      );
      return;
    }

    // All clear, navigate to planner
    // TODO: Navigate to trade planner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening trade planner...')),
    );
  }

  /// Show dialog when user is blocked from trading
  void _showBlockedDialog(BuildContext context, String? message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Action Required'),
          ],
        ),
        content: Text(message ?? 'You must journal your trades before continuing.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show warning dialog for low discipline score
  void _showDisciplineWarningDialog(
    BuildContext context,
    int score, {
    required VoidCallback onProceed,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Low Discipline Warning'),
          ],
        ),
        content: Text(
          'Your discipline score is low ($score/100).\n\nConsider reviewing your last trades or taking a break before opening new positions.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Navigate to behavior dashboard
            },
            child: const Text('Review Trades'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Take A Break'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onProceed();
            },
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    );
  }
}
