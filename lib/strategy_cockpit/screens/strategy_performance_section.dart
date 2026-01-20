import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/strategy_performance_viewmodel.dart';
import '../widgets/strategy_section_container.dart';
import '../widgets/strategy_metric_card.dart';
import '../widgets/strategy_sparkline.dart';

class StrategyPerformanceSection extends StatelessWidget {
  final String strategyId;

  const StrategyPerformanceSection({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyPerformanceViewModel>(
      create: (_) => StrategyPerformanceViewModel(strategyId: strategyId),
      child: Consumer<StrategyPerformanceViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const StrategySectionContainer(
              title: 'Performance',
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.hasError) {
            return const StrategySectionContainer(
              title: 'Performance',
              child: Center(child: Text('Unable to load performance data')),
            );
          }

          return StrategySectionContainer(
            title: 'Performance',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PnL Sparkline
                StrategySparkline(
                  title: 'PnL Trend',
                  values: vm.pnlTrend,
                ),
                const SizedBox(height: 16),

                // Metrics row
                Row(
                  children: [
                    Expanded(
                      child: StrategyMetricCard(
                        label: 'Win Rate',
                        value: _formatPercent(vm.winRate),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StrategyMetricCard(
                        label: 'Max Drawdown',
                        value: _formatNumber(vm.maxDrawdown),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StrategyMetricCard(
                        label: 'Profit Factor',
                        value: vm.pnlTrend.isEmpty
                            ? '—'
                            : _formatNumber(0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Best / Worst cycle row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CycleCard(
                        title: 'Best Cycle',
                        cycle: vm.bestCycle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CycleCard(
                        title: 'Worst Cycle',
                        cycle: vm.worstCycle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatPercent(double value) {
    if (value.isNaN) return '—';
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  String _formatNumber(double value) {
    if (value.isNaN) return '—';
    if (value == double.infinity) return '∞';
    return value.toStringAsFixed(2);
  }
}

class _CycleCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic>? cycle;

  const _CycleCard({
    required this.title,
    required this.cycle,
  });

  @override
  Widget build(BuildContext context) {
    if (cycle == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              const Text('No data yet'),
            ],
          ),
        ),
      );
    }

    final pnl = (cycle!['pnl'] ?? 0).toDouble();
    final label = cycle!['label'] ?? cycle!['id'] ?? 'Cycle';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              label.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _formatPnl(pnl),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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
