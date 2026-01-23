import 'package:flutter/material.dart';
import 'package:riskform_core/models/backtest/backtest_result.dart';

class BacktestMetricsCard extends StatelessWidget {
  final BacktestResult result;

  const BacktestMetricsCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('Total Return', '${(result.totalReturn * 100).toStringAsFixed(1)}%'),
            _row('Max Drawdown', '${(result.maxDrawdown * 100).toStringAsFixed(1)}%'),
            _row('Cycles Completed', '${result.cyclesCompleted}'),
            const SizedBox(height: 8),
            _row('Avg Cycle Return', '${(result.avgCycleReturn * 100).toStringAsFixed(1)}%'),
            _row('Avg Cycle Duration', '${result.avgCycleDurationDays.toStringAsFixed(1)} days'),
            _row('Assignment Rate', '${(result.assignmentRate * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }
}
