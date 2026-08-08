import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:riskform_core/models/backtest/backtest_result.dart';

import '../../../app.dart';

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
    final isProfit = curve.last >= curve.first;
    final lineColor = isProfit ? AppColors.profit : AppColors.loss;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equity Curve', style: AppTextStyles.display(16)),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.8,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Text(
                          _compactCurrency(value),
                          style: AppTextStyles.mono(
                            10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.border),
                      left: BorderSide(color: AppColors.border),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 2.5,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: AppGradients.chartFill(lineColor),
                      ),
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

  String _compactCurrency(double value) {
    if (value.abs() >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}k';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}
