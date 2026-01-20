import 'package:flutter/material.dart';

class StrategySparkline extends StatelessWidget {
  final String title;
  final List<double> values;

  const StrategySparkline({
    super.key,
    required this.title,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder: you can swap this for a real chart widget later.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          alignment: Alignment.center,
          child: Text(
            values.isEmpty ? 'No data yet' : 'Sparkline (${values.length} points)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
