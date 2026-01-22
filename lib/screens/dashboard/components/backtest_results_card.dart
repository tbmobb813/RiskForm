import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/cloud/cloud_backtest_job.dart';
import '../../../services/backtest/backtest_history_repository.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../state/backtest_providers.dart';
import '../../../state/dashboard_providers.dart';
import '../../backtest/cloud_job_status_screen.dart';
import '../../backtest/cloud_backtest_result_screen.dart';
import '../../backtest/cloud_backtest_history_screen.dart';

/// Dashboard card displaying recent backtest results with Local/Cloud/Both toggle.
class BacktestResultsCard extends ConsumerWidget {
  const BacktestResultsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(dashboardDataSourceProvider);
    final auth = ref.watch(authServiceProvider);
    final userId = auth.currentUserId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backtest Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (userId != null)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CloudBacktestHistoryScreen(userId: userId),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DataSourceToggle(currentSource: source, ref: ref),
            const SizedBox(height: 16),
            _ResultsList(source: source, userId: userId),
          ],
        ),
      ),
    );
  }
}

class _DataSourceToggle extends StatelessWidget {
  final DashboardDataSource currentSource;
  final WidgetRef ref;

  const _DataSourceToggle({
    required this.currentSource,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToggleChip(
          label: 'Local',
          isSelected: currentSource == DashboardDataSource.local,
          onTap: () =>
              ref.read(dashboardDataSourceProvider.notifier).setLocal(),
        ),
        const SizedBox(width: 8),
        _ToggleChip(
          label: 'Cloud',
          isSelected: currentSource == DashboardDataSource.cloud,
          onTap: () =>
              ref.read(dashboardDataSourceProvider.notifier).setCloud(),
        ),
        const SizedBox(width: 8),
        _ToggleChip(
          label: 'Both',
          isSelected: currentSource == DashboardDataSource.both,
          onTap: () => ref.read(dashboardDataSourceProvider.notifier).setBoth(),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ResultsList extends ConsumerWidget {
  final DashboardDataSource source;
  final String? userId;

  const _ResultsList({
    required this.source,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyRepo = ref.watch(backtestHistoryRepositoryProvider);
    final localEntries = historyRepo.getAll();

    // If showing only local results
    if (source == DashboardDataSource.local) {
      return _LocalResultsList(entries: localEntries);
    }

    // If showing cloud or both, we need userId
    if (userId == null) {
      return const Center(
        child: Text(
          'Sign in to view cloud backtests',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final cloudService = ref.watch(cloudBacktestServiceProvider);

    return StreamBuilder<List<CloudBacktestJob>>(
      stream: cloudService.watchUserJobs(userId!),
      builder: (context, snapshot) {
        final cloudJobs = snapshot.data ?? [];

        if (source == DashboardDataSource.cloud) {
          return _CloudResultsList(jobs: cloudJobs, cloudService: cloudService);
        }

        // Both
        return _CombinedResultsList(
          localEntries: localEntries,
          cloudJobs: cloudJobs,
          cloudService: cloudService,
        );
      },
    );
  }
}

class _LocalResultsList extends StatelessWidget {
  final List<BacktestHistoryEntry> entries;

  const _LocalResultsList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(message: 'No local backtests yet');
    }

    // Show only the most recent 3
    final displayEntries = entries.take(3).toList();

    return Column(
      children: displayEntries.map((e) => _LocalResultTile(entry: e)).toList(),
    );
  }
}

class _CloudResultsList extends StatelessWidget {
  final List<CloudBacktestJob> jobs;
  final dynamic cloudService;

  const _CloudResultsList({
    required this.jobs,
    required this.cloudService,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const _EmptyState(message: 'No cloud backtests yet');
    }

    // Show only the most recent 3
    final displayJobs = jobs.take(3).toList();

    return Column(
      children: displayJobs
          .map((job) =>
              _CloudResultTile(job: job, cloudService: cloudService))
          .toList(),
    );
  }
}

class _CombinedResultsList extends StatelessWidget {
  final List<BacktestHistoryEntry> localEntries;
  final List<CloudBacktestJob> cloudJobs;
  final dynamic cloudService;

  const _CombinedResultsList({
    required this.localEntries,
    required this.cloudJobs,
    required this.cloudService,
  });

  @override
  Widget build(BuildContext context) {
    if (localEntries.isEmpty && cloudJobs.isEmpty) {
      return const _EmptyState(message: 'No backtests yet');
    }

    // Combine and sort by timestamp, take most recent 3
    final combined = <_CombinedEntry>[];

    for (final e in localEntries) {
      combined.add(_CombinedEntry(
        timestamp: e.timestamp,
        isLocal: true,
        localEntry: e,
      ));
    }

    for (final job in cloudJobs) {
      combined.add(_CombinedEntry(
        timestamp: job.submittedAt,
        isLocal: false,
        cloudJob: job,
      ));
    }

    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final display = combined.take(3).toList();

    return Column(
      children: display.map((entry) {
        if (entry.isLocal) {
          return _LocalResultTile(entry: entry.localEntry!);
        } else {
          return _CloudResultTile(
            job: entry.cloudJob!,
            cloudService: cloudService,
          );
        }
      }).toList(),
    );
  }
}

class _CombinedEntry {
  final DateTime timestamp;
  final bool isLocal;
  final BacktestHistoryEntry? localEntry;
  final CloudBacktestJob? cloudJob;

  _CombinedEntry({
    required this.timestamp,
    required this.isLocal,
    this.localEntry,
    this.cloudJob,
  });
}

class _LocalResultTile extends StatelessWidget {
  final BacktestHistoryEntry entry;

  const _LocalResultTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final result = entry.result;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.computer, color: Colors.blueGrey),
      title: Text(
        entry.label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${_formatReturn(result.totalReturn)} • ${result.cyclesCompleted} cycles',
      ),
      trailing: Text(
        _formatDate(entry.timestamp),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  String _formatReturn(double r) {
    final pct = (r * 100).toStringAsFixed(1);
    return r >= 0 ? '+$pct%' : '$pct%';
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}';
  }
}

class _CloudResultTile extends StatelessWidget {
  final CloudBacktestJob job;
  final dynamic cloudService;

  const _CloudResultTile({
    required this.job,
    required this.cloudService,
  });

  @override
  Widget build(BuildContext context) {
    final config = job.configUsed;
    final statusColor = _statusColor(job.status);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.cloud, color: statusColor),
      title: Text(
        '${config.symbol} - ${config.strategyId}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          _StatusBadge(status: job.status),
          const SizedBox(width: 8),
          Text('v${job.engineVersion}'),
        ],
      ),
      trailing: Text(
        _formatDate(job.submittedAt),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () => _handleTap(context),
    );
  }

  Color _statusColor(CloudBacktestStatus status) {
    return switch (status) {
      CloudBacktestStatus.queued => Colors.orange,
      CloudBacktestStatus.running => Colors.blue,
      CloudBacktestStatus.completed => Colors.green,
      CloudBacktestStatus.failed => Colors.red,
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}';
  }

  Future<void> _handleTap(BuildContext context) async {
    if (job.status == CloudBacktestStatus.completed) {
      final result = await cloudService.getResult(job.jobId);
      if (result == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Result not available yet.')),
        );
        return;
      }
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CloudBacktestResultScreen(result: result),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CloudJobStatusScreen(jobId: job.jobId),
        ),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final CloudBacktestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CloudBacktestStatus.queued => ('Queued', Colors.orange),
      CloudBacktestStatus.running => ('Running', Colors.blue),
      CloudBacktestStatus.completed => ('Done', Colors.green),
      CloudBacktestStatus.failed => ('Failed', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
