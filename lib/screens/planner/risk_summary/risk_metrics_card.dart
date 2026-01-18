import 'package:flutter/material.dart';
import '../../../models/risk_result.dart';

class RiskMetricsCard extends StatelessWidget {
  final RiskResult risk;

  const RiskMetricsCard({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Risk Metrics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _row("Risk % of Account", "${risk.riskPercentOfAccount.toStringAsFixed(1)}%"),
            _row("Assignment Exposure", risk.assignmentExposure ? "Yes" : "No"),
            _row("Capital Locked", "\$${risk.capitalLocked.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}