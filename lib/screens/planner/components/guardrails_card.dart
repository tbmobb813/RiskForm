import 'package:flutter/material.dart';
import '../../../models/risk_result.dart';

class GuardrailsCard extends StatelessWidget {
  final RiskResult risk;

  const GuardrailsCard({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    final critical = <String>[];
    final caution = <String>[];
    final info = <String>[];

    for (final w in risk.warnings) {
      if (w.contains("exceeds") || w.contains("more than 10%")) {
        critical.add(w);
      } else if (w.contains("more than 5%") || w.contains("assignment")) {
        caution.add(w);
      } else {
        info.add(w);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Guardrails",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (critical.isNotEmpty) _section("Critical", critical, Colors.redAccent),
            if (caution.isNotEmpty) _section("Caution", caution, Colors.amber),
            if (info.isNotEmpty) _section("Info", info, Colors.white70),

            if (critical.isEmpty && caution.isEmpty && info.isEmpty)
              const Text("No guardrail issues detected.",
                  style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              )),
          const SizedBox(height: 6),
          ...items.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: color, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(msg)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
