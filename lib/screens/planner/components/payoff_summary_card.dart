import 'package:flutter/material.dart';
import '../../../models/payoff_result.dart';

class PayoffSummaryCard extends StatelessWidget {
  final PayoffResult payoff;

  const PayoffSummaryCard({super.key, required this.payoff});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payoff Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _row("Max Gain", payoff.maxGainString),
            _row("Max Loss", payoff.maxLossString),
            _row("Breakeven", payoff.breakevenString),
            _row("Capital Required", payoff.capitalRequiredString),
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