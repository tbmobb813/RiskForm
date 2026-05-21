import 'package:flutter/material.dart';
import 'package:riskform/app.dart';

class StrategyTile extends StatelessWidget {
  final String name;
  final String strategyId;
  final VoidCallback onTap;
  final bool highlighted;

  const StrategyTile({
    super.key,
    required this.name,
    required this.strategyId,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = StrategyTheme.color(strategyId);
    final badge = StrategyTheme.badge(strategyId);
    final category = StrategyTheme.category(strategyId);

    return Card(
      color: highlighted ? AppColors.primaryDim : null,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(width: 3, color: color),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: AppTextStyles.mono(11, color: color),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.body(
                                15,
                                weight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              category,
                              style: AppTextStyles.body(
                                11,
                              ).copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
