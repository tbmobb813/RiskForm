import 'package:flutter/material.dart';
import '../../../models/backtest/backtest_result.dart';
import '../../../widgets/charts/payoff_chart.dart';

class WheelDrawdownChartCard extends StatelessWidget {
  final BacktestResult result;

  const WheelDrawdownChartCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final ddCurve = _drawdownCurve(result.equityCurve);
    final points = List<Offset>.generate(ddCurve.length, (i) => Offset(i.toDouble(), ddCurve[i]));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Drawdown Curve', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(height: 240, child: PayoffChart(curve: points, breakeven: 0.0)),
          ],
        ),
      ),
    );
  }

  List<double> _drawdownCurve(List<double> equity) {
    if (equity.isEmpty) return [];
    double peak = equity.first;
    final dd = <double>[];

    for (final v in equity) {
      if (v > peak) peak = v;
      dd.add((v - peak) / peak); // negative values
    }
    return dd;
  }
}
