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

      // record journal entries asynchronously (non-blocking to UI)
      try {
        final journal = ref.read(journalAutomationProvider);
        for (final cycle in result.cycles) {
          await journal.recordCycle(cycle);
          if (cycle.hadAssignment) await journal.recordAssignment(cycle);
        }
        await journal.recordBacktest(result);
      } catch (_) {
        // journaling is best-effort; ignore errors here
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
    return Row(
      children: [
        ElevatedButton(
          onPressed: _runBacktest,
          child: const Text('Run Backtest'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _comparisonConfigs.length < 2 ? null : _runComparison,
          child: const Text('Compare Strategies'),
        ),
      ],
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
}
