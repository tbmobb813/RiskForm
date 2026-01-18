import 'package:flutter/material.dart';
import '../../../services/journal/discipline_timeline_service.dart';

class HabitStatsCard extends StatelessWidget {
  final HabitStats habits;

  const HabitStatsCard({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Habit Tracking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Clean Cycle Rate: ${(habits.cleanCycleRate * 100).toStringAsFixed(1)}%'),
            Text('Assignment Avoidance: ${(habits.assignmentAvoidanceRate * 100).toStringAsFixed(1)}%'),
            Text('Plan Adherence: ${(habits.planAdherenceRate * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }
}
