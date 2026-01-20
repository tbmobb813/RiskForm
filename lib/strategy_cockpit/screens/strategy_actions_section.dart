import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/strategy_cockpit_viewmodel.dart';
import '../widgets/strategy_section_container.dart';

class StrategyActionsSection extends StatelessWidget {
  final String strategyId;

  const StrategyActionsSection({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyCockpitViewModel>(
      create: (_) => StrategyCockpitViewModel(strategyId: strategyId),
      child: Consumer<StrategyCockpitViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const StrategySectionContainer(
              title: 'Actions',
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.hasError) {
            return const StrategySectionContainer(
              title: 'Actions',
              child: Center(child: Text('Unable to load strategy state')),
            );
          }

          return StrategySectionContainer(
            title: 'Actions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------------------
                // Open Planner
                // ------------------------------------------------------------
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/planner',
                      arguments: strategyId,
                    );
                  },
                  child: const Text('Open Planner'),
                ),
                const SizedBox(height: 12),

                // ------------------------------------------------------------
                // Pause / Resume / Retire
                // ------------------------------------------------------------
                _LifecycleButtons(vm: vm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LifecycleButtons extends StatelessWidget {
  final StrategyCockpitViewModel vm;

  const _LifecycleButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    final state = vm.strategy?.state.name ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.contains('active')) ...[
          OutlinedButton(
            onPressed: () async {
              await vm.pauseStrategy();
              if (context.mounted) _notify(context, 'Strategy paused');
            },
            child: const Text('Pause Strategy'),
          ),
          const SizedBox(height: 12),
        ],

        if (state.contains('paused')) ...[
          OutlinedButton(
            onPressed: () async {
              await vm.resumeStrategy();
              if (context.mounted) _notify(context, 'Strategy resumed');
            },
            child: const Text('Resume Strategy'),
          ),
          const SizedBox(height: 12),
        ],

        OutlinedButton(
          onPressed: () async {
            await vm.retireStrategy();
            if (context.mounted) _notify(context, 'Strategy retired');
          },
          child: const Text('Retire Strategy'),
        ),
      ],
    );
  }

  void _notify(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
