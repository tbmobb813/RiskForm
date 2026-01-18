import 'package:flutter/material.dart';
import '../../models/backtest/backtest_result.dart';
import 'components/wheel_performance_summary_card.dart';
import 'components/wheel_equity_chart_card.dart';
import 'components/wheel_drawdown_chart_card.dart';
import 'components/wheel_cycle_table_card.dart';

class WheelPerformanceScreen extends StatelessWidget {
  final BacktestResult result;

  const WheelPerformanceScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wheel Performance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WheelPerformanceSummaryCard(result: result),
            const SizedBox(height: 24),
            WheelEquityChartCard(result: result),
            const SizedBox(height: 24),
            WheelDrawdownChartCard(result: result),
            const SizedBox(height: 24),
            WheelCycleTableCard(result: result),
          ],
        ),
      ),
    );
  }
}
