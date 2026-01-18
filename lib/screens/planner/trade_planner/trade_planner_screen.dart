import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/planner_notifier.dart';
import '../components/input_section.dart';
import '../components/optional_inputs_section.dart';
import '../components/account_context_card.dart';

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

                          Navigator.of(context).pushNamed("payoff");
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