import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/strategy_regime_viewmodel.dart';
import '../widgets/strategy_section_container.dart';
import '../widgets/strategy_flag_chip.dart';

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
                // Current Regime Card
                _CurrentRegimeCard(
                  currentRegime: vm.currentRegime,
                  hint: vm.currentRegimeHint,
                ),
                const SizedBox(height: 16),

                // Regime Performance Table
                _RegimePerformanceTable(
                  data: vm.regimePerformance.cast<String, Map<String, dynamic>>(),
                ),
                const SizedBox(height: 16),

                // Weakness Flags
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
            Text(
              'Current Regime',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              currentRegime.isEmpty ? '—' : currentRegime,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RegimePerformanceTable extends StatelessWidget {
  final Map<String, Map<String, dynamic>> data;

  const _RegimePerformanceTable({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('No regime performance data yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regime Performance',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
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
      children: [
        _HeaderCell('Regime'),
        _HeaderCell('PnL'),
        _HeaderCell('Win Rate'),
        _HeaderCell('Discipline'),
      ],
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String value;

  const _DataCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
