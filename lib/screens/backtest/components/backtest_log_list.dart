import 'package:flutter/material.dart';

class BacktestLogList extends StatelessWidget {
  final List<String> steps;

  const BacktestLogList({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulation Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (steps.isEmpty) const Text('No events recorded.'),
            ...steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('- $s'),
                )),
          ],
        ),
      ),
    );
  }
}
