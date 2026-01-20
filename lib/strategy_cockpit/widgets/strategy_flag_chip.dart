import 'package:flutter/material.dart';

class StrategyFlagChip extends StatelessWidget {
  final String label;

  const StrategyFlagChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
}
