import 'package:flutter/material.dart';
import '../../../models/backtest/backtest_result.dart';

class CycleBreakdownCard extends StatelessWidget {
  final List<CycleStats> cycles;

  const CycleBreakdownCard({super.key, required this.cycles});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cycle Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...cycles.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Cycle ${c.index + 1}: ${(c.cycleReturn * 100).toStringAsFixed(1)}% over ${c.durationDays}d — assignment: ${c.hadAssignment ? 'yes' : 'no'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
