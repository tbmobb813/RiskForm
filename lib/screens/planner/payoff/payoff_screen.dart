import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/planner_notifier.dart';
import '../components/payoff_summary_card.dart';
import '../../../widgets/cards/payoff_chart_card.dart';
import 'inputs_recap.dart';

class PayoffScreen extends ConsumerWidget {
  const PayoffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerNotifierProvider);

    if (state.payoff == null) {
      return const Scaffold(
        body: Center(child: Text("No payoff data available.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payoff Overview"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PayoffSummaryCard(payoff: state.payoff!),

              const SizedBox(height: 24),

              PayoffChartCard(payoff: state.payoff!),

              const SizedBox(height: 24),

              InputsRecap(inputs: state.inputs),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.goNamed("risk_summary");
                  },
                  child: const Text("View Risk Summary"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}