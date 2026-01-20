import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cloud/cloud_backtest_job.dart';
import '../../state/backtest_providers.dart';
import 'cloud_job_status_screen.dart';
import 'cloud_backtest_result_screen.dart';

/// Displays a list of all cloud backtest jobs for the current user.
/// Tapping a completed job opens the result screen.
/// Tapping a queued/running/failed job opens the status screen.
class CloudBacktestHistoryScreen extends ConsumerWidget {
  final String userId;

  const CloudBacktestHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloud = ref.watch(cloudBacktestServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backtests'),
      ),
      body: StreamBuilder<List<CloudBacktestJob>>(
        stream: cloud.watchUserJobs(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading jobs: ${snapshot.error}'),
            );
          }

          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No cloud backtests yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Run a backtest in the cloud to see it here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _JobListTile(
                job: job,
                onTap: () => _handleJobTap(context, ref, job),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleJobTap(
    BuildContext context,
    WidgetRef ref,
    CloudBacktestJob job,
  ) async {
    if (job.status == CloudBacktestStatus.completed) {
      final cloud = ref.read(cloudBacktestServiceProvider);
      final result = await cloud.getResult(job.jobId);
      if (result == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Result not available yet.')),
        );
        return;
      }
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CloudBacktestResultScreen(result: result),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CloudJobStatusScreen(jobId: job.jobId),
        ),
      );
    }
  }
}

class _JobListTile extends StatelessWidget {
  final CloudBacktestJob job;
  final VoidCallback onTap;

  const _JobListTile({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final config = job.configUsed;

    return ListTile(
      leading: _StatusIcon(status: job.status),
      title: Text(
        '${config.symbol} - ${config.strategyId}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDate(job.submittedAt)),
          if (job.status == CloudBacktestStatus.failed &&
              job.errorMessage != null)
            Text(
              job.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(status: job.status),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusIcon extends StatelessWidget {
  final CloudBacktestStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      CloudBacktestStatus.queued => (Icons.hourglass_empty, Colors.orange),
      CloudBacktestStatus.running => (Icons.sync, Colors.blue),
      CloudBacktestStatus.completed => (Icons.check_circle, Colors.green),
      CloudBacktestStatus.failed => (Icons.error, Colors.red),
    };

    return Icon(icon, color: color);
  }
}

class _StatusChip extends StatelessWidget {
  final CloudBacktestStatus status;

  const _StatusChip({required this.status});

  Color _color(BuildContext context) {
    return switch (status) {
      CloudBacktestStatus.queued => Colors.orange,
      CloudBacktestStatus.running => Colors.blue,
      CloudBacktestStatus.completed => Colors.green,
      CloudBacktestStatus.failed => Theme.of(context).colorScheme.error,
    };
  }

  String _label() {
    return switch (status) {
      CloudBacktestStatus.queued => 'Queued',
      CloudBacktestStatus.running => 'Running',
      CloudBacktestStatus.completed => 'Completed',
      CloudBacktestStatus.failed => 'Failed',
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
