import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/planner_notifier.dart';
import '../../../models/risk_result.dart';
import 'risk_metrics_card.dart';
import 'guardrails_card.dart';
import 'insights_section.dart';
import 'inputs_recap.dart';

class RiskSummaryScreen extends ConsumerWidget {
  const RiskSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerNotifierProvider);

    if (state.risk == null) {
      return const Scaffold(
        body: Center(child: Text("No risk data available.")),
      );
    }

    final risk = state.risk!;
    final classification = _classifyRisk(risk);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Risk Summary"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RiskClassificationBanner(classification: classification),

              const SizedBox(height: 24),

              RiskMetricsCard(risk: risk),

              const SizedBox(height: 24),

              GuardrailsCard(risk: risk),

              const SizedBox(height: 24),

              InsightsSection(strategyId: state.strategyId),

              const SizedBox(height: 24),

              InputsRecap(inputs: state.inputs),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => GoRouter.of(context).pop(), // back to TradePlannerScreen
                      child: const Text("Adjust Inputs"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => GoRouter.of(context).pushNamed("save_plan"),
                      child: const Text("Save Trade Plan"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

RiskClassification _classifyRisk(RiskResult risk) {
  if (risk.riskPercentOfAccount > 10.0 ||
      risk.capitalLocked > 0.5 * risk.riskPercentOfAccount ||
      risk.warnings.any((w) => w.contains("exceeds"))) {
    return RiskClassification.outsideRules;
  }

  if (risk.riskPercentOfAccount > 5.0 || risk.assignmentExposure) {
    return RiskClassification.borderline;
  }

  return RiskClassification.withinRules;
}

enum RiskClassification {
  withinRules,
  borderline,
  outsideRules,
}

class _RiskClassificationBanner extends StatelessWidget {
  final RiskClassification classification;

  const _RiskClassificationBanner({required this.classification});

  @override
  Widget build(BuildContext context) {
    final color = classification == RiskClassification.withinRules
        ? Colors.green
        : classification == RiskClassification.borderline
            ? Colors.orange
            : Colors.red;

    final text = classification == RiskClassification.withinRules
        ? "Within Rules"
        : classification == RiskClassification.borderline
            ? "Borderline"
            : "Outside Rules";

    final bg = color.withAlpha((0.1 * 255).round());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}