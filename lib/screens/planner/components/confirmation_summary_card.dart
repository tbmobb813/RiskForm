import 'package:flutter/material.dart';
import '../../../models/payoff_result.dart';
import '../../../models/risk_result.dart';

class ConfirmationSummaryCard extends StatelessWidget {
  final String? strategyName;
  final PayoffResult? payoff;
  final RiskResult? risk;

  const ConfirmationSummaryCard({
    super.key,
    required this.strategyName,
    required this.payoff,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review Before Saving",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (strategyName != null)
              _row("Strategy", strategyName!),

            if (payoff != null) ...[
              _row("Max Gain", payoff!.maxGainString),
              _row("Max Loss", payoff!.maxLossString),
              _row("Breakeven", payoff!.breakevenString),
            ],

            if (risk != null) ...[
              _row("Risk % of Account",
                  "${risk!.riskPercentOfAccount.toStringAsFixed(1)}%"),
              _row("Assignment Exposure", risk!.assignmentExposure ? "Yes" : "No"),
            ],
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