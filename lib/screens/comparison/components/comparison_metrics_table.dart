import 'package:flutter/material.dart';
import '../../../models/comparison/comparison_result.dart';
import '../../../models/backtest/backtest_result.dart';

class ComparisonMetricsTable extends StatelessWidget {
  final ComparisonResult result;

  const ComparisonMetricsTable({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final rows = <TableRow>[_headerRow()];
    for (var i = 0; i < result.results.length; i++) {
      rows.add(_resultRow(result.results[i], i));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
          },
          children: rows,
        ),
      ),
    );
  }

  TableRow _headerRow() {
    return const TableRow(
      children: [
        Text("Strategy", style: TextStyle(fontWeight: FontWeight.bold)),
        Text("Total Return", style: TextStyle(fontWeight: FontWeight.bold)),
        Text("Max DD", style: TextStyle(fontWeight: FontWeight.bold)),
        Text("Avg Cycle", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  TableRow _resultRow(BacktestResult result, int index) {
    final label = (result.notes.isNotEmpty) ? result.notes.first : 'Strategy ${index + 1}';
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("${(result.totalReturn * 100).toStringAsFixed(1)}%"),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("${(result.maxDrawdown * 100).toStringAsFixed(1)}%"),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("${(result.avgCycleReturn * 100).toStringAsFixed(1)}%"),
        ),
      ],
    );
  }
}
