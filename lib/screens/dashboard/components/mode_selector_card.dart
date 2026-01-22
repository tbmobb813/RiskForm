import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/state/strategy_controller.dart';

class ModeSelectorCard extends ConsumerWidget {
  const ModeSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(strategyControllerProvider);
    final ctl = ref.read(strategyControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Account Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(state.mode == AccountMode.smallAccount ? 'Small Account' : 'Wheel Strategy'),
            ]),
            ToggleButtons(
              isSelected: [state.mode == AccountMode.smallAccount, state.mode == AccountMode.wheel],
              onPressed: (i) {
                final m = (i == 0) ? AccountMode.smallAccount : AccountMode.wheel;
                ctl.setMode(m);
              },
              children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text('Small')), Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text('Wheel'))],
            ),
          ],
        ),
      ),
    );
  }
}
