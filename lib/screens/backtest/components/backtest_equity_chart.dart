import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:riskform_core/models/backtest/backtest_result.dart';

class BacktestEquityChart extends StatelessWidget {
  final BacktestResult result;

  const BacktestEquityChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final curve = result.equityCurve;
    if (curve.isEmpty) {
      return const Center(child: Text('No equity data'));
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < curve.length; i++) {
      final y = (curve[i] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), y));
    }

    final ys = curve.map((v) => (v as num).toDouble());
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Equity Curve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.8,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withAlpha(40)),
                    ),
                  ],
                  minY: minY,
                  maxY: maxY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

