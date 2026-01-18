import 'package:flutter/material.dart';
import '../../../widgets/charts/payoff_chart.dart';

class BacktestEquityChart extends StatelessWidget {
  final List<double> equityCurve;

  const BacktestEquityChart({super.key, required this.equityCurve});

  @override
  Widget build(BuildContext context) {
    final points = List<Offset>.generate(
      equityCurve.length,
      (i) => Offset(i.toDouble(), equityCurve[i]),
    );

    final breakeven = equityCurve.isNotEmpty ? equityCurve.first : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equity Curve',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: PayoffChart(curve: points, breakeven: breakeven),
            ),
          ],
        ),
      ),
    );
  }
}
