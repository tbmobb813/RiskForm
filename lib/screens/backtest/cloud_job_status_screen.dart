import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cloud/cloud_backtest_job.dart';
import '../../models/cloud/cloud_backtest_result.dart';
import '../../state/backtest_providers.dart';
import 'backtest_screen.dart';

class CloudJobStatusScreen extends ConsumerWidget {
  final String jobId;

  const CloudJobStatusScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloudService = ref.watch(cloudBacktestServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Job Status'),
      ),
      body: StreamBuilder<CloudBacktestJob?>(
        stream: cloudService.watchJob(jobId),
        builder: (context, jobSnapshot) {
          if (jobSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = jobSnapshot.data;
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(job),
                const SizedBox(height: 16),
                _buildTimestampsCard(job),
                const SizedBox(height: 16),
                _buildConfigCard(job),
                if (job.status == CloudBacktestStatus.failed &&
                    job.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(job.errorMessage!),
                ],
                if (job.status == CloudBacktestStatus.completed) ...[
                  const SizedBox(height: 16),
                  _buildResultSection(context, ref, job),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(CloudBacktestJob job) {
    final statusColor = switch (job.status) {
      CloudBacktestStatus.queued => Colors.orange,
      CloudBacktestStatus.running => Colors.blue,
      CloudBacktestStatus.completed => Colors.green,
      CloudBacktestStatus.failed => Colors.red,
    };

    final statusIcon = switch (job.status) {
      CloudBacktestStatus.queued => Icons.hourglass_empty,
      CloudBacktestStatus.running => Icons.sync,
      CloudBacktestStatus.completed => Icons.check_circle,
      CloudBacktestStatus.failed => Icons.error,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Job ID: ${job.jobId.substring(0, 8)}...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Engine: v${job.engineVersion}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (job.status == CloudBacktestStatus.running)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampsCard(CloudBacktestJob job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimestampRow('Submitted', job.submittedAt),
            if (job.startedAt != null)
              _buildTimestampRow('Started', job.startedAt!),
            if (job.completedAt != null)
              _buildTimestampRow('Completed', job.completedAt!),
            if (job.startedAt != null && job.completedAt != null) ...[
              const Divider(),
              _buildDurationRow(job.startedAt!, job.completedAt!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampRow(String label, DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            _formatTimestamp(timestamp),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationRow(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final formatted = _formatDuration(duration);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Duration'),
          Text(
            formatted,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else {
      return '${d.inSeconds}s';
    }
  }

  Widget _buildConfigCard(CloudBacktestJob job) {
    final config = job.configUsed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildConfigRow('Symbol', config.symbol),
            _buildConfigRow('Strategy', config.strategyId),
            _buildConfigRow(
                'Starting Capital', '\$${config.startingCapital.toStringAsFixed(0)}'),
            _buildConfigRow('Max Cycles', config.maxCycles.toString()),
            _buildConfigRow('Date Range',
                '${_formatDate(config.startDate)} - ${_formatDate(config.endDate)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(errorMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(
      BuildContext context, WidgetRef ref, CloudBacktestJob job) {
    final cloudService = ref.watch(cloudBacktestServiceProvider);

    return StreamBuilder<CloudBacktestResult?>(
      stream: cloudService.resultStream(jobId),
      builder: (context, resultSnapshot) {
        final result = resultSnapshot.data;

        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Result Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (result != null) ...[
                  const SizedBox(height: 12),
                  _buildConfigRow(
                    'Total Return',
                    '${(result.backtestResult.totalReturn * 100).toStringAsFixed(2)}%',
                  ),
                  _buildConfigRow(
                    'Max Drawdown',
                    '${(result.backtestResult.maxDrawdown * 100).toStringAsFixed(2)}%',
                  ),
                  _buildConfigRow(
                    'Cycles Completed',
                    result.backtestResult.cyclesCompleted.toString(),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: result != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BacktestScreen(
                                  config: result.backtestResult.configUsed,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Text('View Full Results'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
