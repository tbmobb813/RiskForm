import 'package:flutter/material.dart';
import '../../../models/backtest/backtest_result.dart';

class WheelPerformanceSummaryCard extends StatelessWidget {
  final BacktestResult result;

  const WheelPerformanceSummaryCard({super.key, required this.result});

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
            Text('Total Return: ${(result.totalReturn * 100).toStringAsFixed(1)}%'),
            Text('Max Drawdown: ${(result.maxDrawdown * 100).toStringAsFixed(1)}%'),
            Text('Cycles Completed: ${result.cyclesCompleted}'),
            const SizedBox(height: 12),
            Text('Avg Cycle Return: ${(result.avgCycleReturn * 100).toStringAsFixed(2)}%'),
            Text('Avg Cycle Duration: ${result.avgCycleDurationDays.toStringAsFixed(1)} days'),
            Text('Assignment Rate: ${(result.assignmentRate * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }
}
