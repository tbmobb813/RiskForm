import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/position.dart';
import 'position_card.dart';

// Placeholder provider — you will replace this with real logic later.
final activePositionsProvider = Provider<List<Position>>((ref) {
  return []; // No positions yet
});

class ActivePositionsSection extends ConsumerWidget {
  const ActivePositionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(activePositionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Active Positions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // CASE 1: No positions
        if (positions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text("You have no active positions."),
            ),
          )

        // CASE 2: Render list of positions
        else
          Column(
            children: positions
                .map((pos) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PositionCard(position: pos),
                    ))
                .toList(),
          ),
      ],
    );
  }
}