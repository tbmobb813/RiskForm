import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Viewmodels (assumed to exist in your project)
import 'viewmodels/strategy_performance_viewmodel.dart';
import 'viewmodels/strategy_discipline_viewmodel.dart';
import 'viewmodels/strategy_regime_viewmodel.dart';
import 'viewmodels/strategy_backtest_viewmodel.dart';
import 'viewmodels/strategy_cockpit_viewmodel.dart';

/// =============================================================
/// ROOT SCREEN
/// =============================================================

class StrategyCockpitScreen extends StatelessWidget {
  final String strategyId;

  const StrategyCockpitScreen({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategy Cockpit'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StrategyHeader(strategyId: strategyId),
            const SizedBox(height: 12),
            StrategyPerformanceSection(strategyId: strategyId),
            const SizedBox(height: 12),
            StrategyDisciplineSection(strategyId: strategyId),
            const SizedBox(height: 12),
            StrategyRegimeSection(strategyId: strategyId),
            const SizedBox(height: 12),
            StrategyBacktestSection(strategyId: strategyId),
            const SizedBox(height: 12),
            StrategyActionsSection(strategyId: strategyId),
          ],
        ),
      ),
    );
  }
}

/// =============================================================
/// HEADER
/// =============================================================

class StrategyHeader extends StatelessWidget {
  final String strategyId;

  const StrategyHeader({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyCockpitViewModel>(
      create: (_) => StrategyCockpitViewModel(strategyId: strategyId),
      child: Consumer<StrategyCockpitViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.hasError || vm.strategy == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Unable to load strategy'),
            );
          }

          final strategy = vm.strategy!;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strategy.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    _StateBadge(state: strategy.state.name),
                  ],
                ),
                const SizedBox(height: 8),
                if (strategy.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: strategy.tags
                        .map((t) => Chip(label: Text(t)))
                        .toList(),
                  ),
                if (strategy.tags.isNotEmpty) const SizedBox(height: 12),
                if (strategy.constraints.isNotEmpty)
                  Text(
                    strategy.constraints.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (strategy.constraints.isNotEmpty)
                  const SizedBox(height: 12),
                Text(
                  'Updated ${_formatDate(strategy.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _HeaderActions(vm: vm),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _StateBadge extends StatelessWidget {
  final String state;

  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      'active' => Colors.green,
      'paused' => Colors.orange,
      'retired' => Colors.grey,
      _ => Colors.blueGrey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        state.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final StrategyCockpitViewModel vm;

  const _HeaderActions({required this.vm});

  @override
  Widget build(BuildContext context) {
    final state = vm.strategy?.state.name ?? 'unknown';

    return Row(
      children: [
        if (state == 'active')
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await vm.pauseStrategy();
                if (context.mounted) _notify(context, 'Strategy paused');
              },
              child: const Text('Pause'),
            ),
          ),
        if (state == 'paused')
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await vm.resumeStrategy();
                if (context.mounted) _notify(context, 'Strategy resumed');
              },
              child: const Text('Resume'),
            ),
          ),
        if (state != 'retired') ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await vm.retireStrategy();
                if (context.mounted) _notify(context, 'Strategy retired');
              },
              child: const Text('Retire'),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/editStrategy',
                arguments: vm.strategy?.id,
              );
            },
            child: const Text('Edit'),
          ),
        ),
      ],
    );
  }

  void _notify(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

/// =============================================================
/// SHARED WIDGETS
/// =============================================================

class StrategySectionContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const StrategySectionContainer({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class StrategyMetricCard extends StatelessWidget {
  final String label;
  final String value;

  const StrategyMetricCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class StrategySparkline extends StatelessWidget {
  final String title;
  final List<double> values;

  const StrategySparkline({
    super.key,
    required this.title,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder sparkline; swap for real chart later.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          alignment: Alignment.center,
          child: Text(
            values.isEmpty ? 'No data yet' : 'Sparkline (${values.length} points)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class StrategyFlagChip extends StatelessWidget {
  final String label;

  const StrategyFlagChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
}

/// =============================================================
/// PERFORMANCE MODULE
/// =============================================================

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
                StrategySparkline(
                  title: 'PnL Trend',
                  values: vm.pnlTrend,
                ),
                const SizedBox(height: 16),
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
                        value: vm.pnlTrend.isEmpty ? '—' : _formatNumber(0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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

/// =============================================================
/// DISCIPLINE MODULE
/// =============================================================

class StrategyDisciplineSection extends StatelessWidget {
  final String strategyId;

  const StrategyDisciplineSection({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyDisciplineViewModel>(
      create: (_) => StrategyDisciplineViewModel(strategyId: strategyId),
      child: Consumer<StrategyDisciplineViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const StrategySectionContainer(
              title: 'Discipline',
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.hasError) {
            return const StrategySectionContainer(
              title: 'Discipline',
              child: Center(child: Text('Unable to load discipline data')),
            );
          }

          return StrategySectionContainer(
            title: 'Discipline',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DisciplineSparkline(values: vm.disciplineTrend),
                const SizedBox(height: 16),
                _ViolationsBreakdown(breakdown: vm.violationBreakdown),
                const SizedBox(height: 16),
                _StreakRow(
                  clean: vm.cleanCycleStreak,
                  adherence: vm.adherenceStreak,
                  risk: vm.riskStreak,
                ),
                const SizedBox(height: 16),
                _RecentEventsList(events: vm.recentEvents),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DisciplineSparkline extends StatelessWidget {
  final List<double> values;

  const _DisciplineSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discipline Trend', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          alignment: Alignment.center,
          child: Text(
            values.isEmpty ? 'No data yet' : 'Sparkline (${values.length} points)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ViolationsBreakdown extends StatelessWidget {
  final Map<String, int> breakdown;

  const _ViolationsBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final adherence = breakdown['adherence'] ?? 0;
    final timing = breakdown['timing'] ?? 0;
    final risk = breakdown['risk'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Violations Breakdown', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ViolationTile(label: 'Adherence', count: adherence)),
            const SizedBox(width: 8),
            Expanded(child: _ViolationTile(label: 'Timing', count: timing)),
            const SizedBox(width: 8),
            Expanded(child: _ViolationTile(label: 'Risk', count: risk)),
          ],
        ),
      ],
    );
  }
}

class _ViolationTile extends StatelessWidget {
  final String label;
  final int count;

  const _ViolationTile({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(count.toString(), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  final int clean;
  final int adherence;
  final int risk;

  const _StreakRow({
    required this.clean,
    required this.adherence,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StreakCard(label: 'Clean Cycles', value: clean)),
        const SizedBox(width: 8),
        Expanded(child: _StreakCard(label: 'Adherence', value: adherence)),
        const SizedBox(width: 8),
        Expanded(child: _StreakCard(label: 'Risk', value: risk)),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String label;
  final int value;

  const _StreakCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value.toString(), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _RecentEventsList extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  const _RecentEventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text('No recent discipline events');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Discipline Events', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...events.map((e) => _EventTile(event: e)),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final label = event['label'] ?? event['id'] ?? 'Cycle';
    final score = (event['disciplineScore'] ?? 0).toDouble();

    return Card(
      elevation: 0,
      child: ListTile(
        title: Text(label.toString()),
        subtitle: Text('Discipline Score: ${score.toStringAsFixed(1)}'),
      ),
    );
  }
}

/// =============================================================
/// REGIME MODULE
/// =============================================================

class StrategyRegimeSection extends StatelessWidget {
  final String strategyId;

  const StrategyRegimeSection({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyRegimeViewModel>(
      create: (_) => StrategyRegimeViewModel(strategyId: strategyId),
      child: Consumer<StrategyRegimeViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const StrategySectionContainer(
              title: 'Regime Behavior',
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.hasError) {
            return const StrategySectionContainer(
              title: 'Regime Behavior',
              child: Center(child: Text('Unable to load regime data')),
            );
          }

          return StrategySectionContainer(
            title: 'Regime Behavior',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CurrentRegimeCard(
                  currentRegime: vm.currentRegime,
                  hint: vm.currentRegimeHint,
                ),
                const SizedBox(height: 16),
                _RegimePerformanceTable(data: vm.regimePerformance),
                const SizedBox(height: 16),
                if (vm.regimeWeaknesses.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vm.regimeWeaknesses
                        .map((flag) => StrategyFlagChip(label: flag))
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurrentRegimeCard extends StatelessWidget {
  final String currentRegime;
  final String hint;

  const _CurrentRegimeCard({
    required this.currentRegime,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Regime', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(currentRegime.isEmpty ? '—' : currentRegime, style: Theme.of(context).textTheme.titleMedium),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(hint, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _RegimePerformanceTable extends StatelessWidget {
  final Map<String, Map<String, dynamic>> data;

  const _RegimePerformanceTable({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Text('No regime performance data yet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Regime Performance', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Theme.of(context).dividerColor, width: 0.5),
          columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
          children: [
            _headerRow(),
            ...data.entries.map((e) => _dataRow(e.key, e.value)),
          ],
        ),
      ],
    );
  }

  TableRow _headerRow() {
    return const TableRow(
      children: [_HeaderCell('Regime'), _HeaderCell('PnL'), _HeaderCell('Win Rate'), _HeaderCell('Discipline')],
    );
  }

  TableRow _dataRow(String regime, Map<String, dynamic> stats) {
    final pnl = (stats['pnl'] ?? 0).toDouble();
    final winRate = (stats['winRate'] ?? 0).toDouble();
    final discipline = (stats['avgDiscipline'] ?? 0).toDouble();

    return TableRow(
      children: [
        _DataCell(regime),
        _DataCell(_formatNumber(pnl)),
        _DataCell('${(winRate * 100).toStringAsFixed(1)}%'),
        _DataCell(discipline.toStringAsFixed(1)),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value == double.infinity) return '∞';
    if (value.isNaN) return '—';
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}';
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(8), child: Text(label, style: Theme.of(context).textTheme.bodySmall));
  }
}

class _DataCell extends StatelessWidget {
  final String value;

  const _DataCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(8), child: Text(value, style: Theme.of(context).textTheme.bodyMedium));
  }
}

/// =============================================================
/// BACKTEST MODULE
/// =============================================================

class StrategyBacktestSection extends StatelessWidget {
  final String strategyId;

  const StrategyBacktestSection({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyBacktestViewModel>(
      create: (_) => StrategyBacktestViewModel(strategyId: strategyId),
      child: Consumer<StrategyBacktestViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const StrategySectionContainer(title: 'Backtests', child: Center(child: CircularProgressIndicator()));
          }

          if (vm.hasError) {
            return const StrategySectionContainer(title: 'Backtests', child: Center(child: Text('Unable to load backtest data')));
          }

          return StrategySectionContainer(
            title: 'Backtests',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LatestBacktestCard(latest: vm.latestBacktest),
                const SizedBox(height: 16),
                _BacktestHistoryList(history: vm.backtestHistory),
                const SizedBox(height: 16),
                _BacktestActions(strategyId: strategyId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LatestBacktestCard extends StatelessWidget {
  final Map<String, dynamic>? latest;

  const _LatestBacktestCard({required this.latest});

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(12), child: Text('No backtest results yet', style: Theme.of(context).textTheme.bodyMedium)));
    }

    final summary = latest!['summary'] ?? {};
    final pnl = (summary['totalPnl'] ?? 0).toDouble();
    final winRate = (summary['winRate'] ?? 0).toDouble();
    final cycles = summary['cycles'] ?? 0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest Backtest', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Total PnL: ${_formatPnl(pnl)}'),
            Text('Win Rate: ${(winRate * 100).toStringAsFixed(1)}%'),
            Text('Cycles: $cycles'),
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

class _BacktestHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const _BacktestHistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const Text('No backtest history yet');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Backtest History', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 8), ...history.map((item) => _HistoryTile(item: item))]);
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final summary = item['summary'] ?? {};
    final pnl = (summary['totalPnl'] ?? 0).toDouble();
    final winRate = (summary['winRate'] ?? 0).toDouble();
    final completedAt = item['completedAt'];

    return Card(
      elevation: 0,
      child: ListTile(
        title: Text('Backtest ${item['id']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PnL: ${_formatPnl(pnl)}'),
            Text('Win Rate: ${(winRate * 100).toStringAsFixed(1)}%'),
            if (completedAt != null) Text('Completed: $completedAt'),
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

class _BacktestActions extends StatelessWidget {
  final String strategyId;

  const _BacktestActions({required this.strategyId});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Expanded(child: OutlinedButton(onPressed: () { Navigator.of(context).pushNamed('/cloudBacktest', arguments: strategyId); }, child: const Text('Run Backtest'))), const SizedBox(width: 12), Expanded(child: OutlinedButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Re-run not implemented yet'))); }, child: const Text('Re-run Last')))]);
  }
}

/// =============================================================
/// ACTIONS MODULE
/// =============================================================

class StrategyActionsSection extends StatelessWidget {
  final String strategyId;

  const StrategyActionsSection({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyCockpitViewModel>(
      create: (_) => StrategyCockpitViewModel(strategyId: strategyId),
      child: Consumer<StrategyCockpitViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const StrategySectionContainer(title: 'Actions', child: Center(child: CircularProgressIndicator()));
          }

          if (vm.hasError) {
            return const StrategySectionContainer(title: 'Actions', child: Center(child: Text('Unable to load strategy state')));
          }

          return StrategySectionContainer(
            title: 'Actions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/planner', arguments: strategyId);
                  },
                  child: const Text('Open Planner'),
                ),
                const SizedBox(height: 12),
                _LifecycleButtons(vm: vm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LifecycleButtons extends StatelessWidget {
  final StrategyCockpitViewModel vm;

  const _LifecycleButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    final state = vm.strategy?.state.name ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state == 'active') ...[
          OutlinedButton(
            onPressed: () async {
              await vm.pauseStrategy();
              if (context.mounted) _notify(context, 'Strategy paused');
            },
            child: const Text('Pause Strategy'),
          ),
          const SizedBox(height: 12),
        ],
        if (state == 'paused') ...[
          OutlinedButton(
            onPressed: () async {
              await vm.resumeStrategy();
              if (context.mounted) _notify(context, 'Strategy resumed');
            },
            child: const Text('Resume Strategy'),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: () async {
            await vm.retireStrategy();
            if (context.mounted) _notify(context, 'Strategy retired');
          },
          child: const Text('Retire Strategy'),
        ),
      ],
    );
  }

  void _notify(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
