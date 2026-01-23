import 'package:flutter/material.dart';
import 'package:riskform_core/models/backtest/backtest_result.dart';

class CycleBreakdownCard extends StatelessWidget {
  final List<CycleStats> cycles;

  const CycleBreakdownCard({super.key, required this.cycles});

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('No cycles')));
    }

    final avgReturn = cycles.map((c) => c.cycleReturn).fold<double>(0.0, (a, b) => a + b) / cycles.length;
    final avgDuration = cycles.map((c) => c.durationDays.toDouble()).fold<double>(0.0, (a, b) => a + b) / cycles.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cycle Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              _stat('Count', '${cycles.length}'),
              const SizedBox(width: 12),
              _stat('Avg Return', '${(avgReturn * 100).toStringAsFixed(2)}%'),
              const SizedBox(width: 12),
              _stat('Avg Duration', '${avgDuration.toStringAsFixed(1)}d'),
            ]),
            const SizedBox(height: 12),
            Column(
              children: cycles
                  .asMap()
                  .entries
                  .map((e) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Cycle ${e.key + 1} — ${(e.value.cycleReturn * 100).toStringAsFixed(2)}%'),
                        subtitle: Text('${e.value.durationDays} days'),
                        trailing: Text(e.value.hadAssignment ? 'Assigned' : 'Expired', style: TextStyle(color: e.value.hadAssignment ? Colors.orange : Colors.black54)),
                      ))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
