import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:riskform/strategy_cockpit/analytics_providers.dart';
import 'package:riskform/strategy_cockpit/sync_providers.dart';
import 'package:riskform/services/market_data_providers.dart';

import '../viewmodels/strategy_cockpit_viewmodel.dart';
import '../widgets/strategy_section_container.dart';
import 'package:riskform/models/strategy.dart';
import 'package:riskform/strategy_cockpit/default_services.dart';

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
            create: (context) {
              final container = ProviderScope.containerOf(context, listen: false);
              final md = container.read(marketDataServiceProvider);
              final recs = container.read(strategyRecommendationsEngineProvider);
              final narr = container.read(strategyNarrativeEngineProvider);
              final live = container.read(liveSyncManagerProvider);
              return StrategyCockpitViewModel(
                strategyId: widget.strategyId,
                marketDataService: md,
                recsEngine: recs,
                narrativeEngine: narr,
                liveSyncManager: live,
              );
            },
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
    final state = vm.strategy?.state.toString().split('.').last ?? 'unknown';

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
