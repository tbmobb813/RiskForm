import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/planner_notifier.dart';
import '../../backtest/backtest_screen.dart';
import '../../../models/backtest/backtest_config.dart';
import '../../../state/account_context_provider.dart';
import '../../../state/comparison_provider.dart';
import '../../../models/comparison/comparison_config.dart';
import '../../../services/engines/comparison_helper.dart';
import '../../comparison/comparison_screen.dart';
// trade plan persistence handled by PlannerNotifier
import '../components/confirmation_summary_card.dart';
import '../components/notes_field.dart';
import '../components/tags_section.dart';

class SavePlanScreen extends ConsumerWidget {
  const SavePlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerNotifierProvider);
    final planner = ref.read(plannerNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Save Trade Plan"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConfirmationSummaryCard(
                strategyName: state.strategyName,
                payoff: state.payoff,
                risk: state.risk,
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    // run a small deterministic parameter sweep and open ComparisonScreen
                    final accountAsync = ref.watch(accountContextProvider);
                    final startingCapital = accountAsync.value?.accountSize ?? 10000.0;
                    final basePrice = state.payoff?.breakeven ?? 100.0;

                    final baseConfig = BacktestConfig(
                      startingCapital: startingCapital,
                      maxCycles: 10,
                      pricePath: [basePrice],
                      strategyId: state.strategyId ?? 'wheel',
                      symbol: 'SPY',
                      startDate: DateTime.now().subtract(const Duration(days: 365)),
                      endDate: DateTime.now(),
                    );

                    // deterministic drifts for regime comparisons
                    final drifts = [-0.005, -0.001, 0.0, 0.001, 0.005];
                    final configs = generateSweepConfigs(base: baseConfig, drifts: drifts, length: 252);

                    final runner = ref.read(comparisonRunnerProvider);
                    final comparisonConfig = ComparisonConfig(configs: configs);
                    final result = await runner.run(comparisonConfig);

                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (c) => ComparisonScreen(result: result)),
                      );
                    }
                  },
                  child: const Text('Compare Parameter Sweep'),
                ),
              ),

              const SizedBox(height: 24),

              NotesField(
                initialValue: state.notes ?? "",
                onChanged: planner.updateNotes,
              ),

              const SizedBox(height: 24),

              TagsSection(
                selectedTags: state.tags,
                onChanged: planner.updateTags,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Build a BacktestConfig from current planner state and account.
                    final accountAsync = ref.watch(accountContextProvider);
                    final startingCapital = accountAsync.value?.accountSize ?? 10000.0;
                    final basePrice = state.payoff?.breakeven ?? 100.0;
                    final prices = List<double>.generate(60, (i) => basePrice + (i - 30) * 0.5);

                    final config = BacktestConfig(
                      startingCapital: startingCapital,
                      maxCycles: 10,
                      pricePath: prices,
                      strategyId: state.strategyId ?? 'wheel',
                      symbol: 'SPY',
                      startDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                      endDate: DateTime.now(),
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (c) => BacktestScreen(config: config)),
                    );
                  },
                  child: const Text('Simulate this plan'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await planner.savePlan();
                    if (!ok) return;

                    // The notifier handled persistence and wheel update.

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Trade plan saved. No position has been placed."),
                        ),
                      );
                      context.goNamed("dashboard");
                    }
                  },
                  child: const Text("Save Trade Plan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}