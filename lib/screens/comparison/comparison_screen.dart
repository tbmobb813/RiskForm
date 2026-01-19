import 'package:flutter/material.dart';
import '../../models/comparison/comparison_result.dart';
import 'components/comparison_metrics_table.dart';
import 'components/comparison_equity_chart.dart';

class ComparisonScreen extends StatelessWidget {
  final ComparisonResult result;

  const ComparisonScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Strategy Comparison")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ComparisonMetricsTable(result: result),
            const SizedBox(height: 24),
            ComparisonEquityChart(result: result),
          ],
        ),
      ),
    );
  }
}
