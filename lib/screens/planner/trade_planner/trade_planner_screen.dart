import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/planner_notifier.dart';
import '../components/input_section.dart';
import '../components/optional_inputs_section.dart';
import '../components/account_context_card.dart';
import '../components/hints_section.dart';
import '../components/recommended_range_slider.dart';
import '../components/input_summary_card.dart';
import '../../../..//services/strategy/strategy_health_service.dart';

class TradePlannerScreen extends ConsumerWidget {
  const TradePlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerNotifierProvider);
    final planner = ref.read(plannerNotifierProvider.notifier);

    if (state.strategyId == null) {
      return const Scaffold(
        body: Center(child: Text("No strategy selected.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.strategyName ?? "Trade Planner"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Strategy Header
              Text(
                state.strategyName!,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                state.strategyDescription ?? "",
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 12),
              // Strategy health score
              Builder(builder: (context) {
                final health = StrategyHealthService().compute(inputs: state.inputs, payoff: state.payoff);
                final score = (health.overall * 100).toStringAsFixed(0);
                return Card(
                  color: Colors.blueGrey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Strategy Health', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Overall: $score%', style: const TextStyle(fontSize: 12)),
                        ]),
                        CircularProgressIndicator(value: health.overall, color: Colors.green),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Account Context
              const AccountContextCard(),

              const SizedBox(height: 24),

              // Required Inputs
              InputSection(
                strategyId: state.strategyId!,
                onInputsChanged: (inputs) {
                  planner.updateInputs(inputs);
                },
              ),

              const SizedBox(height: 12),
              // Parameter sliders with recommended overlays
              const RecommendedRangeSlider(field: 'delta', min: 0.0, max: 1.0),
              const SizedBox(height: 12),
              const RecommendedRangeSlider(field: 'dte', min: 1.0, max: 120.0),
              const SizedBox(height: 12),
              const RecommendedRangeSlider(field: 'width', min: 1.0, max: 100.0),

              const SizedBox(height: 12),
              // Summary card that reflects persisted slider values
              const InputSummaryCard(),

              const SizedBox(height: 12),
              const HintsSection(),

              const SizedBox(height: 16),

              // Optional Inputs
              OptionalInputsSection(
                onNotesChanged: (notes) {},
              ),

              const SizedBox(height: 24),

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.inputs == null
                      ? null
                      : () async {
                          final ok = await planner.computePayoff();
                          if (!ok) return;
                          if (!context.mounted) return;

                          context.pushNamed("payoff");
                        },
                  child: const Text("Review Payoff & Risk"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}