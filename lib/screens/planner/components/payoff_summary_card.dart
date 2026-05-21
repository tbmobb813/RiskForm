import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/app.dart';
import '../../../models/payoff_result.dart';
import '../../../state/planner_notifier.dart';

class PayoffSummaryCard extends ConsumerWidget {
  final PayoffResult payoff;

  const PayoffSummaryCard({super.key, required this.payoff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategyId = ref.watch(
      plannerNotifierProvider.select((s) => s.strategyId),
    );
    final color = StrategyTheme.color(strategyId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payoff Summary',
              style: AppTextStyles.body(15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'MAX GAIN',
                    value: payoff.maxGainString,
                    valueColor: AppColors.profit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'MAX LOSS',
                    value: payoff.maxLossString,
                    valueColor: AppColors.loss,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'BREAKEVEN',
                    value: payoff.breakevenString,
                    valueColor: AppColors.signal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'CAPITAL REQ.',
                    value: payoff.capitalRequiredString,
                    valueColor: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body(
              9,
            ).copyWith(color: AppColors.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.mono(15, color: valueColor)),
        ],
      ),
    );
  }
}
