import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/backtest/backtest_config.dart';
import '../../models/backtest/backtest_result.dart';
import '../../state/backtest_engine_provider.dart';
import '../../state/historical_providers.dart';
import '../../state/journal_providers.dart';
import '../../state/comparison_provider.dart';
import '../../models/comparison/comparison_config.dart';
import '../../screens/comparison/comparison_screen.dart';
import '../../state/backtest_providers.dart';
import '../../services/backtest/backtest_history_repository.dart';
import '../../services/firebase/auth_service.dart';
import '../../models/cloud/cloud_backtest_job.dart';
import 'cloud_job_status_screen.dart';
import 'components/backtest_metrics_card.dart';
import 'components/backtest_equity_chart.dart';
import 'components/backtest_cycle_breakdown_card.dart';
import 'components/backtest_log_list.dart';

class BacktestScreen extends ConsumerStatefulWidget {
  final BacktestConfig config;

  const BacktestScreen({super.key, required this.config});

  @override
  ConsumerState<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends ConsumerState<BacktestScreen> {
  bool _isRunning = true;
  BacktestResult? _result;
  final List<BacktestConfig> _comparisonConfigs = [];
  BacktestConfig? _lastRunConfig;

  // Cloud backtest state
  String? _cloudJobId;
  CloudBacktestJob? _cloudJob;
  bool _isSubmittingToCloud = false;
  StreamSubscription<CloudBacktestJob?>? _cloudJobSub;

  @override
  void initState() {
    super.initState();
    _runBacktest();
  }

  Future<void> _runBacktest() async {
    final engine = ref.read(backtestEngineProvider);
    final historicalRepo = ref.read(historicalRepositoryProvider);

    try {
      // 1. Fetch historical OHLCV
      final prices = await historicalRepo.getDailyPrices(
        symbol: widget.config.symbol,
        start: widget.config.startDate,
        end: widget.config.endDate,
      );

      // 2. Convert to price path (close prices)
      final pricePath = prices.map((p) => p.close).toList();

      // 3. Run backtest with real data
      final runConfig = widget.config.copyWith(pricePath: pricePath);
      final result = await Future(() => engine.run(runConfig));

      // persist to history (in-memory) for quick access
      try {
        final historyRepo = ref.read(backtestHistoryRepositoryProvider);
        historyRepo.add(BacktestHistoryEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          label: widget.config.label ?? '${widget.config.strategyId} ${widget.config.symbol}',
          timestamp: DateTime.now(),
          result: result,
        ));
      } catch (_) {}

      // record journal entries asynchronously (non-blocking to UI)
      try {
        final journal = ref.read(journalAutomationProvider);
        final symbol = widget.config.symbol;
        for (final cycle in result.cycles) {
          await journal.recordCycle(cycle, symbol);
          if (cycle.hadAssignment) await journal.recordAssignment(cycle, symbol);
        }
        await journal.recordBacktest(result);
      } catch (e, stackTrace) {
        // Journaling is best-effort; log and continue so UI/backtest flow is not blocked.
        debugPrint('Journal recording failed: $e');
        debugPrint('$stackTrace');
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        _isRunning = false;
        _lastRunConfig = runConfig;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _isRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backtest failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backtest Results')),
      body: _isRunning
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? const Center(child: Text('Unable to run backtest'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final result = _result!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComparisonSection(),
          const SizedBox(height: 24),
          _buildRunButtons(),
          const SizedBox(height: 24),
          BacktestMetricsCard(result: result),
          const SizedBox(height: 24),
          BacktestEquityChart(equityCurve: result.equityCurve),
          const SizedBox(height: 24),
          if (result.cycles.isNotEmpty) ...[
            CycleBreakdownCard(cycles: result.cycles),
            const SizedBox(height: 24),
          ],
          BacktestLogList(steps: result.notes),
        ],
      ),
    );
  }

  Widget _buildRunButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: _runBacktest,
              child: const Text('Run Backtest'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isSubmittingToCloud ? null : _submitToCloud,
              child: _isSubmittingToCloud
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run in Cloud'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _comparisonConfigs.length < 2 ? null : _runComparison,
              child: const Text('Compare Strategies'),
            ),
          ],
        ),
        if (_cloudJob != null) ...[
          const SizedBox(height: 12),
          _buildCloudJobStatus(),
        ],
      ],
    );
  }

  Widget _buildCloudJobStatus() {
    final job = _cloudJob!;
    final statusColor = switch (job.status) {
      CloudBacktestStatus.queued => Colors.orange,
      CloudBacktestStatus.running => Colors.blue,
      CloudBacktestStatus.completed => Colors.green,
      CloudBacktestStatus.failed => Colors.red,
    };

    return Card(
      child: InkWell(
        onTap: () {
          if (_cloudJobId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CloudJobStatusScreen(jobId: _cloudJobId!),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.cloud, color: statusColor),
              const SizedBox(width: 8),
              Text('Cloud Job: ${job.status.name}'),
              if (job.status == CloudBacktestStatus.running) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              const Spacer(),
              Text(
                'ID: ${_cloudJobId?.substring(0, 8) ?? ""}...',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Strategy Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._comparisonConfigs.map((c) => _configRow(c)),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addCurrentConfigToComparison,
                  child: const Text('Add Current Config'),
                ),
                const SizedBox(width: 12),
                if (_lastRunConfig != null)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _comparisonConfigs.add(_lastRunConfig!);
                      });
                    },
                    child: const Text('Add Last Run'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _configRow(BacktestConfig c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(c.strategyId),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() => _comparisonConfigs.remove(c));
            },
          ),
        ],
      ),
    );
  }

  void _addCurrentConfigToComparison() {
    final config = widget.config;
    setState(() => _comparisonConfigs.add(config));
  }

  Future<void> _runComparison() async {
    final runner = ref.read(comparisonRunnerProvider);
    final comparisonConfig = ComparisonConfig(configs: _comparisonConfigs);
    final result = await runner.run(comparisonConfig);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => ComparisonScreen(result: result)),
    );
  }

  @override
  void dispose() {
    // Ensure any active Cloud job subscription is cancelled to avoid leaks
    _cloudJobSub?.cancel();
    _cloudJobSub = null;
    super.dispose();
  }

  Future<void> _submitToCloud() async {
    final auth = ref.read(authServiceProvider);
    final userId = auth.currentUserId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to run cloud backtests')),
      );
      return;
    }

    setState(() => _isSubmittingToCloud = true);

    try {
      final cloudService = ref.read(cloudBacktestServiceProvider);
      final jobId = await cloudService.submitJob(
        userId: userId,
        configMap: widget.config.toMap(),
        engineVersion: '1.0.0',
      );

      setState(() {
        _cloudJobId = jobId;
        _isSubmittingToCloud = false;
      });

      // Cancel any previous subscription to avoid leaks, then listen for updates
      await _cloudJobSub?.cancel();
      _cloudJobSub = cloudService.jobStream(jobId).listen((job) async {
        if (!mounted) return;
        setState(() => _cloudJob = job);

        if (job?.status == CloudBacktestStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cloud backtest completed!')),
          );
          // Stop listening once the job is finished
          await _cloudJobSub?.cancel();
          _cloudJobSub = null;
        } else if (job?.status == CloudBacktestStatus.failed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cloud backtest failed: ${job?.errorMessage ?? "Unknown error"}')),
          );
          await _cloudJobSub?.cancel();
          _cloudJobSub = null;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submitted to cloud. Job ID: $jobId')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingToCloud = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }
}
