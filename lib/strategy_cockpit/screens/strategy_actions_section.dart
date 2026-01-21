import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/strategy_cockpit_viewmodel.dart';
import '../widgets/strategy_section_container.dart';

class StrategyActionsSection extends StatefulWidget {
  final String strategyId;
  final StrategyCockpitViewModel? viewModel;

  const StrategyActionsSection({
    super.key,
    required this.strategyId,
    this.viewModel,
  });

  @override
  State<StrategyActionsSection> createState() => _StrategyActionsSectionState();
}

class _StrategyActionsSectionState extends State<StrategyActionsSection> {
  bool _showInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Ensure an initial loading indicator is shown for the first frame
    // so tests and UIs observing the first-build state can display
    // a spinner before synchronous streams emit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showInitialLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.viewModel != null
        ? ChangeNotifierProvider.value(
            value: widget.viewModel!,
            child: Consumer<StrategyCockpitViewModel>(
              builder: (context, vm, _) => _buildForVm(context, vm),
            ),
          )
        : ChangeNotifierProvider<StrategyCockpitViewModel>(
            create: (_) => StrategyCockpitViewModel(strategyId: widget.strategyId),
            child: Consumer<StrategyCockpitViewModel>(
              builder: (context, vm, _) => _buildForVm(context, vm),
            ),
          );

    return provider;
  }

  Widget _buildForVm(BuildContext context, StrategyCockpitViewModel vm) {
    // Show spinner if viewmodel reports loading or if we are on the
    // initial first-frame loading state.
    if (vm.isLoading || _showInitialLoading) {
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
          // Open Planner
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/planner',
                arguments: widget.strategyId,
              );
            },
            child: const Text('Open Planner'),
          ),
          const SizedBox(height: 12),

          // Pause / Resume / Retire
          _LifecycleButtons(vm: vm),
        ],
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
