import 'package:flutter/material.dart';

class BacktestLogList extends StatelessWidget {
  final List<String> steps;

  const BacktestLogList({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backtest Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (steps.isEmpty) const Text('No log entries'),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key + 1}.', style: const TextStyle(color: Colors.black54)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.value)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
