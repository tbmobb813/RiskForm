import 'package:flutter/material.dart';
import '../../models/position.dart';

class LifecycleIndicator extends StatelessWidget {
  final Position position;

  const LifecycleIndicator({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final daysLeft = position.dte;
    final stage = _stageFor(daysLeft);

    return Row(
      children: [
        Icon(_iconFor(stage), size: 16),
        const SizedBox(width: 6),
        Text(stage),
      ],
    );
  }

  String _stageFor(int daysLeft) {
    if (daysLeft > 30) return "Early";
    if (daysLeft > 10) return "Mid";
    return "Late";
  }

  IconData _iconFor(String stage) {
    switch (stage) {
      case "Early":
        return Icons.timelapse;
      case "Mid":
        return Icons.hourglass_bottom;
      case "Late":
        return Icons.warning_amber_rounded;
      default:
        return Icons.help_outline;
    }
  }
}
