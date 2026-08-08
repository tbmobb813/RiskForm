import 'package:flutter/material.dart';
import 'package:riskform_core/models/backtest/backtest_result.dart';

import '../../../app.dart';

class BacktestMetricsCard extends StatelessWidget {
  final BacktestResult result;

  const BacktestMetricsCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isProfit = result.totalReturn >= 0;
    final returnColor = isProfit ? AppColors.profit : AppColors.loss;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Summary', style: AppTextStyles.display(16)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isProfit ? '+' : ''}${(result.totalReturn * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.mono(28, color: returnColor).copyWith(
                    fontWeight: FontWeight.w700,
                    shadows: AppGradients.glow(returnColor, opacity: 0.4),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Icon(
                    isProfit ? Icons.trending_up : Icons.trending_down,
                    color: returnColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Total Return',
                    style: AppTextStyles.body(
                      12,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(
              'Max Drawdown',
              '${(result.maxDrawdown * 100).toStringAsFixed(1)}%',
            ),
            _row('Cycles Completed', '${result.cyclesCompleted}'),
            const SizedBox(height: 8),
            _row(
              'Avg Cycle Return',
              '${(result.avgCycleReturn * 100).toStringAsFixed(1)}%',
            ),
            _row(
              'Avg Cycle Duration',
              '${result.avgCycleDurationDays.toStringAsFixed(1)} days',
            ),
            _row(
              'Assignment Rate',
              '${(result.assignmentRate * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body(
              13,
            ).copyWith(color: AppColors.textSecondary),
          ),
          Text(value, style: AppTextStyles.mono(13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
