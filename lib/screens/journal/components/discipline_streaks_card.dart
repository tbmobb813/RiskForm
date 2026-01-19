import 'package:flutter/material.dart';
import '../../../services/journal/discipline_timeline_service.dart';

class DisciplineStreaksCard extends StatelessWidget {
  final DisciplineStreaks streaks;

  const DisciplineStreaksCard({super.key, required this.streaks});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discipline Streaks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Disciplined Days: ${streaks.disciplineStreakDays}'),
            Text('Clean Cycles: ${streaks.cleanCycleStreak}'),
            Text('No Assignments: ${streaks.noAssignmentStreak}'),
          ],
        ),
      ),
    );
  }
}
