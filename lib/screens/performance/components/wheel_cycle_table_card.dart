import 'package:flutter/material.dart';
import '../../../models/backtest/backtest_result.dart';

class WheelCycleTableCard extends StatelessWidget {
  final BacktestResult result;

  const WheelCycleTableCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final cycles = result.cycles;

    if (cycles.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('No completed cycles in this backtest.')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cycle Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...cycles.map(_buildRow),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(CycleStats c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Cycle ${c.index + 1}: ${(c.cycleReturn * 100).toStringAsFixed(2)}% over ${c.durationDays}d, assignment: ${c.hadAssignment ? "yes" : "no"}',
      ),
    );
  }
}
