import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/backtest/backtest_config.dart';
import '../../models/backtest/backtest_result.dart';
import '../../state/backtest_engine_provider.dart';
import 'components/backtest_metrics_card.dart';
import 'components/backtest_equity_chart.dart';
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

  @override
  void initState() {
    super.initState();
    _runBacktest();
  }

  Future<void> _runBacktest() async {
    final engine = ref.read(backtestEngineProvider);

    final result = await Future(() => engine.run(widget.config));

    if (!mounted) return;
    setState(() {
      _result = result;
      _isRunning = false;
    });
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
          BacktestMetricsCard(result: result),
          const SizedBox(height: 24),
          BacktestEquityChart(equityCurve: result.equityCurve),
          const SizedBox(height: 24),
          BacktestLogList(steps: result.notes),
        ],
      ),
    );
  }
}
