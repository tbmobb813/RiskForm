import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform_core/models/backtest/backtest_config.dart';
import 'package:riskform_core/models/backtest/backtest_result.dart';

import '../../state/backtest_engine_provider.dart';
import '../../services/firebase/auth_service.dart';
import '../../state/backtest_providers.dart';
import '../../models/cloud/cloud_backtest_job.dart';
import 'cloud_job_status_screen.dart';
import '../../state/comparison_provider.dart';
import '../../models/comparison/comparison_config.dart';
import '../../screens/comparison/comparison_screen.dart';
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
  bool _running = false;
  BacktestResult? _result;
  final List<BacktestConfig> _comparisonConfigs = [];
  BacktestConfig? _lastRunConfig;
  // Cloud submission state
  String? _cloudJobId;
  CloudBacktestJob? _cloudJob;
  bool _isSubmittingToCloud = false;
  StreamSubscription<CloudBacktestJob?>? _cloudJobSub;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      final engine = ref.read(backtestEngineProvider);
      final res = await Future(() => engine.run(widget.config));
      if (!mounted) return;
      setState(() {
        _result = res;
        _lastRunConfig = widget.config;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backtest failed: $e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _submitToCloud() async {
    final auth = ref.read(authServiceProvider);
    final userId = auth.currentUserId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to run in cloud')));
      return;
    }

    setState(() => _isSubmittingToCloud = true);
    try {
      final cloud = ref.read(cloudBacktestServiceProvider);
      final jobId = await cloud.submitJob(userId: userId, configMap: widget.config.toMap());
      setState(() {
        _cloudJobId = jobId;
        _isSubmittingToCloud = false;
      });

      await _cloudJobSub?.cancel();
      _cloudJobSub = cloud.jobStream(jobId).listen((job) {
        if (!mounted) return;
        setState(() => _cloudJob = job);
        if (job?.status == CloudBacktestStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud backtest completed')));
        } else if (job?.status == CloudBacktestStatus.failed) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud backtest failed')));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingToCloud = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
    }
  }

  void _addCurrentConfigToComparison() {
    setState(() => _comparisonConfigs.add(widget.config));
  }

  Future<void> _runComparison() async {
    final runner = ref.read(comparisonRunnerProvider);
    final comparisonConfig = ComparisonConfig(configs: _comparisonConfigs);
    final result = await runner.run(comparisonConfig);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (c) => ComparisonScreen(result: result)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backtest')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              ElevatedButton(onPressed: _running ? null : _run, child: _running ? const CircularProgressIndicator() : const Text('Run')),
              const SizedBox(width: 12),
              if (_result != null) ElevatedButton(onPressed: () {}, child: const Text('Save')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _isSubmittingToCloud ? null : _submitToCloud, child: _isSubmittingToCloud ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Run in Cloud')),
            ]),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comparison', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._comparisonConfigs.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c.strategyId),
                              IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _comparisonConfigs.remove(c)))
                            ],
                          ),
                        )),
                    Row(children: [
                      ElevatedButton(onPressed: _addCurrentConfigToComparison, child: const Text('Add Current')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _lastRunConfig == null ? null : () => setState(() => _comparisonConfigs.add(_lastRunConfig!)), child: const Text('Add Last Run')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _comparisonConfigs.length < 2 ? null : _runComparison, child: const Text('Compare')),
                    ])
                  ],
                ),
              ),
            ),
                    const SizedBox(height: 16),
                    if (_cloudJob != null) Card(
                      child: ListTile(
                        leading: Icon(_cloudJob!.status == CloudBacktestStatus.running ? Icons.sync : _cloudJob!.status == CloudBacktestStatus.completed ? Icons.check_circle : _cloudJob!.status == CloudBacktestStatus.failed ? Icons.error : Icons.hourglass_empty),
                        title: Text('Cloud Job: ${_cloudJob!.status.name.toUpperCase()}'),
                        subtitle: Text('ID: ${_cloudJobId ?? ''}'),
                        trailing: IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => CloudJobStatusScreen(jobId: _cloudJobId!))); }),
                      ),
                    ),
            if (_result != null) ...[
              BacktestMetricsCard(result: _result!),
              const SizedBox(height: 12),
              BacktestEquityChart(result: _result!),
              const SizedBox(height: 12),
              if (_result!.cycles.isNotEmpty) CycleBreakdownCard(cycles: _result!.cycles),
              const SizedBox(height: 12),
              BacktestLogList(steps: _result!.notes),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cloudJobSub?.cancel();
    _cloudJobSub = null;
    super.dispose();
  }
}
