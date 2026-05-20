import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/imported_trade.dart';
import '../../services/firebase/auth_service.dart';
import '../../state/import_notifier.dart';
import 'widgets/trade_review_item.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Trades'),
        actions: [
          if (state.step == ImportStep.reviewing ||
              state.step == ImportStep.done)
            TextButton(
              onPressed: () => ref.read(importProvider.notifier).reset(),
              child: const Text('Start Over'),
            ),
        ],
      ),
      body: switch (state.step) {
        ImportStep.idle || ImportStep.picked => _BrokerPicker(state: state),
        ImportStep.reviewing => _ReviewScreen(state: state),
        ImportStep.saving => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving trades…'),
            ],
          ),
        ),
        ImportStep.done => _DoneScreen(state: state),
        ImportStep.error => _ErrorScreen(state: state),
      },
    );
  }
}

// ── Step 1: Broker picker + file picker ───────────────────────────────────────

class _BrokerPicker extends ConsumerWidget {
  final ImportState state;
  const _BrokerPicker({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(importProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Broker',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Export your transaction history as CSV from your broker, '
            'then select the matching format below.',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: 24),

          // Broker cards
          ...ImportBroker.values.map(
            (b) => _BrokerCard(
              broker: b,
              selected: state.broker == b,
              onTap: () => notifier.setBroker(b),
            ),
          ),

          const SizedBox(height: 32),

          // Export instructions
          _ExportInstructions(broker: state.broker),

          const SizedBox(height: 32),

          // Pick file button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.step == ImportStep.picked
                  ? null
                  : () => notifier.pickAndParse(),
              icon: const Icon(Icons.upload_file),
              label: Text(
                state.step == ImportStep.picked
                    ? 'Reading file…'
                    : 'Choose CSV File',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerCard extends StatelessWidget {
  final ImportBroker broker;
  final bool selected;
  final VoidCallback onTap;

  const _BrokerCard({
    required this.broker,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon => switch (broker) {
    ImportBroker.tastytrade => Icons.trending_up,
    ImportBroker.thinkorswim => Icons.candlestick_chart,
    ImportBroker.robinhood => Icons.bar_chart,
  };

  String get _name => switch (broker) {
    ImportBroker.tastytrade => 'tastytrade',
    ImportBroker.thinkorswim => 'thinkorSwim / TD Ameritrade / Schwab',
    ImportBroker.robinhood => 'Robinhood',
  };

  String get _hint => switch (broker) {
    ImportBroker.tastytrade => 'Account → History → Export Transactions (CSV)',
    ImportBroker.thinkorswim => 'Monitor → Account Statement → Export to CSV',
    ImportBroker.robinhood => 'Account → Statements & History → Download CSV',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: selected ? cs.primary : cs.onSurface.withAlpha(160),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.onPrimaryContainer : cs.onSurface,
                    ),
                  ),
                  Text(
                    _hint,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? cs.onPrimaryContainer.withAlpha(180)
                          : cs.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ExportInstructions extends StatelessWidget {
  final ImportBroker broker;
  const _ExportInstructions({required this.broker});

  List<String> get _steps => switch (broker) {
    ImportBroker.tastytrade => [
      'Log in at tastytrade.com',
      'Go to Account → History',
      'Set your date range (up to 1 year)',
      'Click "Export" → Download as CSV',
    ],
    ImportBroker.thinkorswim => [
      'Open thinkorSwim desktop or log in at schwab.com',
      'Go to Monitor → Account Statement',
      'Set your date range',
      'Click the export icon → Save as CSV',
    ],
    ImportBroker.robinhood => [
      'Log in at robinhood.com',
      'Go to Account → Statements & History',
      'Click "Download" next to any period',
      'Open the downloaded CSV',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to export from ${broker == ImportBroker.tastytrade
                ? 'tastytrade'
                : broker == ImportBroker.thinkorswim
                ? 'thinkorSwim'
                : 'Robinhood'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._steps.indexed.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.$1 + 1}. ',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Review parsed trades ──────────────────────────────────────────────

class _ReviewScreen extends ConsumerWidget {
  final ImportState state;
  const _ReviewScreen({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(importProvider.notifier);
    final uid = ref.watch(currentUserIdProvider);
    final cs = Theme.of(context).colorScheme;

    final options = state.trades.where((t) => t.isOption).length;
    final equities = state.trades.length - options;

    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: cs.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.fileName ?? 'Imported file',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${state.trades.length} trades found  ·  '
                      '$options options  ·  $equities equities',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              // Select all / none
              TextButton(
                onPressed: () => notifier.selectAll(
                  state.selectedCount < state.trades.length,
                ),
                child: Text(
                  state.selectedCount < state.trades.length
                      ? 'Select All'
                      : 'Deselect All',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const SizedBox(width: 42),
              SizedBox(
                width: 52,
                child: Text(
                  'DATE',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.8,
                    color: cs.onSurface.withAlpha(100),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  'SYMBOL / ACTION',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.8,
                    color: cs.onSurface.withAlpha(100),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'DETAILS',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.8,
                    color: cs.onSurface.withAlpha(100),
                  ),
                ),
              ),
              Text(
                'VALUE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  color: cs.onSurface.withAlpha(100),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Trade list
        Expanded(
          child: ListView.separated(
            itemCount: state.trades.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => TradeReviewItem(
              trade: state.trades[i],
              index: i,
              onToggle: notifier.toggleTrade,
            ),
          ),
        ),

        // Footer action bar
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(color: cs.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${state.selectedCount} of ${state.trades.length} selected',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withAlpha(160),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: state.selectedCount == 0 || uid == null
                      ? null
                      : () => notifier.confirmImport(uid),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Import ${state.selectedCount} Trade'
                    '${state.selectedCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 3: Done ──────────────────────────────────────────────────────────────

class _DoneScreen extends ConsumerWidget {
  final ImportState state;
  const _DoneScreen({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              '${state.savedCount} trade'
              '${state.savedCount == 1 ? '' : 's'} imported',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'All selected trades have been saved to your journal.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => ref.read(importProvider.notifier).reset(),
              child: const Text('Import Another File'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error screen ──────────────────────────────────────────────────────────────

class _ErrorScreen extends ConsumerWidget {
  final ImportState state;
  const _ErrorScreen({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Import Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Unknown error.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => ref.read(importProvider.notifier).reset(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
