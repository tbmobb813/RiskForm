import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:riskform/strategy_cockpit/analytics_providers.dart';
import 'package:riskform/strategy_cockpit/sync_providers.dart';
import 'package:riskform/services/market_data_providers.dart';

import '../viewmodels/strategy_cockpit_viewmodel.dart';

class StrategyHeader extends StatelessWidget {
  final String strategyId;

  const StrategyHeader({
    super.key,
    required this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StrategyCockpitViewModel>(
      create: (context) {
        final container = ProviderScope.containerOf(context, listen: false);
        final md = container.read(marketDataServiceProvider);
        final recs = container.read(strategyRecommendationsEngineProvider);
        final narr = container.read(strategyNarrativeEngineProvider);
        final liveSync = container.read(liveSyncManagerProvider);
        return StrategyCockpitViewModel(
          strategyId: strategyId,
          marketDataService: md,
          recsEngine: recs,
          narrativeEngine: narr,
          liveSyncManager: liveSync,
        );
      },
      child: Consumer<StrategyCockpitViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.hasError || vm.strategy == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Unable to load strategy'),
            );
          }

          final strategy = vm.strategy!;
          final stateName = strategy.state.toString().split('.').last;
          final constraintsSummary =
              (strategy.constraints.isNotEmpty) ? strategy.constraints.toString() : null;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------------------
                // Strategy Name + State Badge
                // ------------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strategy.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    _StateBadge(state: stateName),
                  ],
                ),
                const SizedBox(height: 8),

                // ------------------------------------------------------------
                // Tags
                // ------------------------------------------------------------
                if (strategy.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: strategy.tags.map((t) => Chip(label: Text(t))).toList(),
                  ),
                if (strategy.tags.isNotEmpty) const SizedBox(height: 12),

                // ------------------------------------------------------------
                // Constraints Summary
                // ------------------------------------------------------------
                if (constraintsSummary != null)
                  Text(
                    constraintsSummary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (constraintsSummary != null) const SizedBox(height: 12),

                // ------------------------------------------------------------
                // Last Updated
                // ------------------------------------------------------------
                Text(
                  'Updated ${_formatDate(strategy.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                // ------------------------------------------------------------
                // Header Actions Row
                // ------------------------------------------------------------
                _HeaderActions(vm: vm),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _StateBadge extends StatelessWidget {
  final String state;

  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (state == 'active') {
      color = Colors.green;
    } else if (state == 'paused') {
      color = Colors.orange;
    } else if (state == 'retired') {
      color = Colors.grey;
    } else {
      color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        state.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final StrategyCockpitViewModel vm;

  const _HeaderActions({required this.vm});

  @override
  Widget build(BuildContext context) {
    final stateName = vm.strategy?.state.toString().split('.').last ?? 'unknown';

    return Row(
      children: [
        if (stateName == 'active')
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await vm.pauseStrategy();
                if (context.mounted) _notify(context, 'Strategy paused');
              },
              child: const Text('Pause'),
            ),
          ),

        if (stateName == 'paused')
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await vm.resumeStrategy();
                if (context.mounted) _notify(context, 'Strategy resumed');
              },
              child: const Text('Resume'),
            ),
          ),

        if (stateName != 'retired') ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await vm.retireStrategy();
                if (context.mounted) _notify(context, 'Strategy retired');
              },
              child: const Text('Retire'),
            ),
          ),
        ],

        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/editStrategy',
                arguments: vm.strategy?.id,
              );
            },
            child: const Text('Edit'),
          ),
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
