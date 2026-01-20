import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/strategy_backtest_viewmodel.dart';
import '../widgets/strategy_section_container.dart';

class StrategyBacktestSection extends StatelessWidget {
  final String strategyId;

  const StrategyBacktestSection({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyBacktestViewModel>(
      create: (_) => StrategyBacktestViewModel(strategyId: strategyId),
      child: Consumer<StrategyBacktestViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const StrategySectionContainer(
              title: 'Backtests',
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.hasError) {
            return const StrategySectionContainer(
              title: 'Backtests',
              child: Center(child: Text('Unable to load backtest data')),
            );
          }

          return StrategySectionContainer(
            title: 'Backtests',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------------------
                // Latest Backtest Summary
                // ------------------------------------------------------------
                _LatestBacktestCard(latest: vm.latestBacktest),
                const SizedBox(height: 16),

                // ------------------------------------------------------------
                // Backtest History
                // ------------------------------------------------------------
                _BacktestHistoryList(history: vm.backtestHistory),
                const SizedBox(height: 16),

                // ------------------------------------------------------------
                // Actions
                // ------------------------------------------------------------
                _BacktestActions(strategyId: strategyId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LatestBacktestCard extends StatelessWidget {
  final Map<String, dynamic>? latest;

  const _LatestBacktestCard({required this.latest});

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'No backtest results yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final summary = latest!['summary'] ?? {};
    final pnl = (summary['totalPnl'] ?? 0).toDouble();
    final winRate = (summary['winRate'] ?? 0).toDouble();
    final cycles = summary['cycles'] ?? 0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest Backtest', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Total PnL: ${_formatPnl(pnl)}'),
            Text('Win Rate: ${(winRate * 100).toStringAsFixed(1)}%'),
            Text('Cycles: $cycles'),
          ],
        ),
      ),
    );
  }

  String _formatPnl(double pnl) {
    final sign = pnl > 0 ? '+' : '';
    return '$sign${pnl.toStringAsFixed(2)}';
  }
}

class _BacktestHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const _BacktestHistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Text('No backtest history yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Backtest History', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...history.map((item) => _HistoryTile(item: item)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final summary = item['summary'] ?? {};
    final pnl = (summary['totalPnl'] ?? 0).toDouble();
    final winRate = (summary['winRate'] ?? 0).toDouble();
    final completedAt = item['completedAt'] ?? null;

    return Card(
      elevation: 0,
      child: ListTile(
        title: Text('Backtest ${item['id']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PnL: ${_formatPnl(pnl)}'),
            Text('Win Rate: ${(winRate * 100).toStringAsFixed(1)}%'),
            if (completedAt != null) Text('Completed: $completedAt'),
          ],
        ),
      ),
    );
  }

  String _formatPnl(double pnl) {
    final sign = pnl > 0 ? '+' : '';
    return '$sign${pnl.toStringAsFixed(2)}';
  }
}

class _BacktestActions extends StatelessWidget {
  final String strategyId;

  const _BacktestActions({required this.strategyId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Navigate to CloudBacktestScreen
              Navigator.of(context).pushNamed(
                '/cloudBacktest',
                arguments: strategyId,
              );
            },
            child: const Text('Run Backtest'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Trigger re-run logic (Phase 5.5)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Re-run not implemented yet')),
              );
            },
            child: const Text('Re-run Last'),
          ),
        ),
      ],
    );
  }
}
