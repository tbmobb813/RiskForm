import 'package:flutter/material.dart';
import '../../../models/backtest/backtest_result.dart';
import '../../../widgets/charts/payoff_chart.dart';

class WheelEquityChartCard extends StatelessWidget {
  final BacktestResult result;

  const WheelEquityChartCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final curve = result.equityCurve;
    final points = List<Offset>.generate(curve.length, (i) => Offset(i.toDouble(), curve[i]));
    final breakeven = curve.isNotEmpty ? curve.first : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Equity Curve', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(height: 240, child: PayoffChart(curve: points, breakeven: breakeven)),
          ],
        ),
      ),
    );
  }
}
