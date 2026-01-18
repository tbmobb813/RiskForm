import 'package:flutter/material.dart';
import '../models/backtest/backtest_result.dart';

class CycleTimeline extends StatelessWidget {
  final List<CycleStats> cycles;

  const CycleTimeline({super.key, required this.cycles});

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cycle Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cycles.length,
                itemBuilder: (context, idx) {
                  final c = cycles[idx];
                  // Simple representation: small block per cycle colored by outcome
                  Color color;
                  switch (c.outcome) {
                    case CycleOutcome.assigned:
                      color = Colors.orange;
                      break;
                    case CycleOutcome.calledAway:
                      color = Colors.blue;
                      break;
                    case CycleOutcome.expiredOTM:
                      color = Colors.green;
                      break;
                    default:
                      color = Colors.grey;
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        Container(width: 40, height: 20, color: color),
                        const SizedBox(height: 6),
                        Text('#${c.index}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
