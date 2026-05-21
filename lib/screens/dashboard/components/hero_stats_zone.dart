import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/app.dart';
import 'package:riskform/state/account_providers.dart';
import 'package:riskform/state/discipline_providers.dart';
import 'package:riskform/state/journal_providers.dart';
import 'discipline_ring.dart';

class HeroStatsZone extends ConsumerWidget {
  const HeroStatsZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(accountBalanceProvider);
    final riskDeployed = ref.watch(riskDeployedProvider);
    final available = balance - riskDeployed;

    final repo = ref.watch(journalRepositoryProvider);
    final entries = repo.getAll();
    final scoring = ref.read(disciplineScoringProvider);
    final score = entries.isEmpty ? 0.0 : scoring.compute(entries).score;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CountUpTile(label: 'BALANCE', value: balance, prefix: '\$'),
          ),
          _divider(),
          Expanded(
            child: _CountUpTile(
              label: 'AVAILABLE',
              value: available,
              prefix: '\$',
              valueColor: available < 0 ? AppColors.loss : null,
            ),
          ),
          _divider(),
          Expanded(
            child: _CountUpTile(
              label: 'RISK ON',
              value: riskDeployed,
              prefix: '\$',
              valueColor: riskDeployed > 0 ? AppColors.signal : null,
            ),
          ),
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DisciplineRing(score: score, size: 60),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _CountUpTile extends StatelessWidget {
  final String label;
  final double value;
  final String prefix;
  final Color? valueColor;

  const _CountUpTile({
    required this.label,
    required this.value,
    this.prefix = '',
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.body(
              10,
            ).copyWith(color: AppColors.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              '$prefix${v.toStringAsFixed(2)}',
              style: AppTextStyles.mono(
                14,
                color: valueColor ?? AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
