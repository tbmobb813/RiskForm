import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/backtest/backtest_config.dart';
import '../../models/backtest/backtest_result.dart';
import '../../state/backtest_engine_provider.dart';
import '../../state/historical_providers.dart';
import '../../state/journal_providers.dart';
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
      final result = await Future(() => engine.run(widget.config.copyWith(pricePath: pricePath)));

      // record journal entries asynchronously (non-blocking to UI)
      try {
        final journal = ref.read(journalAutomationProvider);
        for (final cycle in result.cycles) {
          await journal.recordCycle(cycle);
          if (cycle.hadAssignment) await journal.recordAssignment(cycle);
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
}
