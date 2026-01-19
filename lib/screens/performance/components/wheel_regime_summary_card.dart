import 'package:flutter/material.dart';
import '../../../models/backtest/backtest_result.dart';

class WheelRegimeSummaryCard extends StatelessWidget {
  final BacktestResult result;

  const WheelRegimeSummaryCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Regime Breakdown",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _row(
              "Uptrend",
              result.uptrendAvgCycleReturn,
              result.uptrendAssignmentRate,
            ),
            _row(
              "Downtrend",
              result.downtrendAvgCycleReturn,
              result.downtrendAssignmentRate,
            ),
            _row(
              "Sideways",
              result.sidewaysAvgCycleReturn,
              result.sidewaysAssignmentRate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double avgRet, double assignRate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$label — "
        "Avg cycle: ${(avgRet * 100).toStringAsFixed(2)}%, "
        "Assignment: ${(assignRate * 100).toStringAsFixed(1)}%",
      ),
    );
  }
}
