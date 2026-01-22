import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'backtest_comparison_viewmodel.dart';

class BacktestComparisonModule extends StatelessWidget {
  final String strategyId;

  const BacktestComparisonModule({required this.strategyId, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BacktestComparisonViewModel(strategyId: strategyId),
      child: const _BacktestComparisonView(),
    );
  }
}

class _BacktestComparisonView extends StatelessWidget {
  const _BacktestComparisonView();

  @override
  Widget build(BuildContext context) {
    return Consumer<BacktestComparisonViewModel>(
      builder: (context, vm, _) {
        if (vm.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final result = vm.result;
        if (result == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BestConfigCard(result.bestConfig),
              const SizedBox(height: 12),
              _WeakConfigCard(result.worstConfig),
              const SizedBox(height: 12),
              _RegimeWeaknessCard(result.regimeWeaknesses),
              const SizedBox(height: 12),
              _SummaryNoteCard(result.summaryNote),
              const SizedBox(height: 24),
              _ComparisonTable(result.runs),
            ],
          ),
        );
      },
    );
  }
}

class _BestConfigCard extends StatelessWidget {
  final Map<String, dynamic>? config;

  const _BestConfigCard(this.config);

  @override
  Widget build(BuildContext context) {
    if (config == null) return const SizedBox.shrink();

    return _CockpitCard(
      title: 'Best Configuration',
      child: Text(
        config.toString(),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _WeakConfigCard extends StatelessWidget {
  final Map<String, dynamic>? config;

  const _WeakConfigCard(this.config);

  @override
  Widget build(BuildContext context) {
    if (config == null) return const SizedBox.shrink();

    return _CockpitCard(
      title: 'Weak Configuration',
      child: Text(
        config.toString(),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _RegimeWeaknessCard extends StatelessWidget {
  final Map<String, dynamic> weaknesses;

  const _RegimeWeaknessCard(this.weaknesses);

  @override
  Widget build(BuildContext context) {
    if (weaknesses.isEmpty) {
      return _CockpitCard(
        title: 'Regime Weaknesses',
        child: const Text('No regime weaknesses detected.'),
      );
    }

    return _CockpitCard(
      title: 'Regime Weaknesses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weaknesses.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('- ${e.value}'),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryNoteCard extends StatelessWidget {
  final String note;

  const _SummaryNoteCard(this.note);

  @override
  Widget build(BuildContext context) {
    return _CockpitCard(
      title: 'Summary',
      child: Text(
        note,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final List<Map<String, dynamic>> runs;

  const _ComparisonTable(this.runs);

  @override
  Widget build(BuildContext context) {
    return _CockpitCard(
      title: 'Backtest Comparison',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Run')),
            DataColumn(label: Text('PnL')),
            DataColumn(label: Text('Win Rate')),
            DataColumn(label: Text('Drawdown')),
            DataColumn(label: Text('Params')),
          ],
          rows: runs.map((r) {
            final m = r['metrics'] ?? {};
            return DataRow(
              cells: [
                DataCell(Text(r['runId'] ?? '')),
                DataCell(Text('${m['pnl'] ?? ''}')),
                DataCell(Text('${m['winRate'] ?? ''}')),
                DataCell(Text('${m['maxDrawdown'] ?? ''}')),
                DataCell(Text(r['parameters']?.toString() ?? '')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CockpitCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _CockpitCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
