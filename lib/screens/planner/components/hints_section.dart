import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/planner_notifier.dart';

class HintsSection extends ConsumerWidget {
  const HintsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerNotifierProvider);
    final bundle = state.hintsBundle;

    if (bundle == null || bundle.hints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Planner Hints', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...bundle.hints.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconForSeverity(h.severity),
                      const SizedBox(width: 8),
                      Expanded(child: Text(h.message, style: TextStyle(color: _colorForSeverity(h.severity)))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _iconForSeverity(String s) {
    switch (s) {
      case 'danger':
        return const Icon(Icons.error, color: Colors.red);
      case 'warning':
        return const Icon(Icons.warning, color: Colors.orange);
      default:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }

  Color _colorForSeverity(String s) {
    switch (s) {
      case 'danger':
        return Colors.red.shade200;
      case 'warning':
        return Colors.orange.shade200;
      default:
        return Colors.blue.shade200;
    }
  }
}
