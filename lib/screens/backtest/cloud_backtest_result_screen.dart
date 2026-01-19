import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cloud/cloud_backtest_result.dart';
import '../../models/backtest/backtest_result.dart';
import '../../state/backtest_providers.dart';
import 'components/backtest_metrics_card.dart';
import 'components/backtest_equity_chart.dart';
import 'components/backtest_cycle_breakdown_card.dart';
import 'components/backtest_log_list.dart';

/// Displays a completed cloud backtest result.
/// Reuses the same visual components as the local BacktestScreen.
///
/// Can be constructed with either:
/// - A [CloudBacktestResult] directly (for direct navigation)
/// - A [jobId] to fetch the result (for go_router navigation)
class CloudBacktestResultScreen extends ConsumerWidget {
  final CloudBacktestResult? result;
  final String? jobId;

  /// Constructor for direct navigation with a result.
  const CloudBacktestResultScreen({super.key, required CloudBacktestResult this.result})
      : jobId = null;

  /// Constructor for go_router navigation with a jobId.
  const CloudBacktestResultScreen.fromJobId({super.key, required String this.jobId})
      : result = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If we have a direct result, use it
    if (result != null) {
      return _ResultContent(result: result!);
    }

    // Otherwise, fetch by jobId
    final cloudService = ref.watch(cloudBacktestServiceProvider);

    return FutureBuilder<CloudBacktestResult?>(
      future: cloudService.getResult(jobId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cloud Backtest Result')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final fetchedResult = snapshot.data;
        if (fetchedResult == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cloud Backtest Result')),
            body: const Center(child: Text('Result not found')),
          );
        }

        return _ResultContent(result: fetchedResult);
      },
    );
  }
}

class _ResultContent extends StatelessWidget {
  final CloudBacktestResult result;

  const _ResultContent({required this.result});

  BacktestResult get backtest => result.backtestResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backtest Result'),
        actions: [
          _EngineVersionBadge(version: backtest.engineVersion),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(result: result),
            const SizedBox(height: 16),
            BacktestMetricsCard(result: backtest),
            const SizedBox(height: 16),
            BacktestEquityChart(equityCurve: backtest.equityCurve),
            const SizedBox(height: 16),
            if (backtest.cycles.isNotEmpty) ...[
              CycleBreakdownCard(cycles: backtest.cycles),
              const SizedBox(height: 16),
            ],
            BacktestLogList(steps: backtest.notes),
          ],
        ),
      ),
    );
  }
}

class _EngineVersionBadge extends StatelessWidget {
  final String version;

  const _EngineVersionBadge({required this.version});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'v$version',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final CloudBacktestResult result;

  const _HeaderCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final backtest = result.backtestResult;
    final config = backtest.configUsed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Cloud Backtest Completed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Job ID', value: '${result.jobId.substring(0, 8)}...'),
            _InfoRow(label: 'Symbol', value: config.symbol),
            _InfoRow(label: 'Strategy', value: config.strategyId),
            _InfoRow(
              label: 'Created',
              value: _formatDateTime(result.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
