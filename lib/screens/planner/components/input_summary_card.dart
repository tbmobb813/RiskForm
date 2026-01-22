import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/planner_notifier.dart';

class InputSummaryCard extends ConsumerWidget {
  const InputSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerNotifierProvider);
    final inputs = state.inputs;

    if (inputs == null) return const SizedBox.shrink();

    final delta = inputs.delta != null ? inputs.delta!.toStringAsFixed(3) : '—';
    final width = inputs.width != null ? inputs.width!.toStringAsFixed(2) : '—';
    final dte = inputs.expiration != null ? inputs.expiration!.difference(DateTime.now()).inDays.toString() : '—';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Delta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(delta, style: Theme.of(context).textTheme.bodyMedium),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Width', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(width, style: Theme.of(context).textTheme.bodyMedium),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(dte, style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ],
        ),
      ),
    );
  }
}
