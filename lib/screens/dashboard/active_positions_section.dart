import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/position.dart';
import '../../services/data/position_repository.dart';
import '../../state/open_positions_provider.dart';
import 'add_position_sheet.dart';
import 'position_card.dart';

/// The signed-in user's open positions; empty while loading or on error.
final activePositionsProvider = Provider<List<Position>>((ref) {
  return ref
      .watch(openPositionsStreamProvider)
      .maybeWhen(data: (positions) => positions, orElse: () => const []);
});

class ActivePositionsSection extends ConsumerWidget {
  const ActivePositionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(activePositionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Active Positions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => AddPositionSheet.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
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
                .map(
                  (pos) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PositionCard(position: pos),
                        if (pos.id != null)
                          TextButton(
                            onPressed: () => ref
                                .read(positionRepositoryProvider)
                                .close(pos.id!),
                            child: const Text('Mark closed'),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
