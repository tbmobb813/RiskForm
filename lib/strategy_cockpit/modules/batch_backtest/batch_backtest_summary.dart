import 'package:flutter/material.dart';

class BatchBacktestSummary extends StatelessWidget {
  final Map<String, dynamic> summary;

  const BatchBacktestSummary({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    final best = summary['bestConfig'];
    final worst = summary['worstConfig'];
    final regimeWeaknesses = Map<String, dynamic>.from(summary['regimeWeaknesses'] ?? {});
    final note = summary['summaryNote'] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CockpitCard(
          title: "Best Configuration",
          child: Text(best?.toString() ?? "—"),
        ),
        const SizedBox(height: 12),
        _CockpitCard(
          title: "Weak Configuration",
          child: Text(worst?.toString() ?? "—"),
        ),
        const SizedBox(height: 12),
        _CockpitCard(
          title: "Regime Weaknesses",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: regimeWeaknesses.entries
                .map<Widget>((e) => Text("- ${e.value}"))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _CockpitCard(
          title: "Summary",
          child: Text(note),
        ),
      ],
    );
  }
}

class _CockpitCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _CockpitCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
