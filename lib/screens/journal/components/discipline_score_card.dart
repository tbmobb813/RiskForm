import 'package:flutter/material.dart';
import '../../../models/journal/discipline_score.dart';

class DisciplineScoreCard extends StatelessWidget {
  final DisciplineScore score;

  const DisciplineScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discipline Score: ${score.score.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _row('Plan Adherence', score.planAdherence),
            _row('Cycle Quality', score.cycleQuality),
            _row('Assignment Behavior', score.assignmentBehavior),
            _row('Regime Awareness', score.regimeAwareness),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: ${(value * 100).toStringAsFixed(1)}%'),
    );
  }
}
