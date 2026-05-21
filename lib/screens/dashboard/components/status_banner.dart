import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/app.dart';
import 'package:riskform/state/discipline_providers.dart';
import 'package:riskform/state/journal_providers.dart';

enum _TradingStatus { clear, journalPending, blocked }

class StatusBanner extends ConsumerWidget {
  const StatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(journalRepositoryProvider);
    final entries = repo.getAll();
    final scoring = ref.read(disciplineScoringProvider);

    final score = entries.isEmpty ? 0.0 : scoring.compute(entries).score;

    final todayEntries = entries.where((e) {
      final now = DateTime.now();
      return e.timestamp.year == now.year &&
          e.timestamp.month == now.month &&
          e.timestamp.day == now.day;
    }).toList();

    final status = score < 40
        ? _TradingStatus.blocked
        : todayEntries.isEmpty
        ? _TradingStatus.journalPending
        : _TradingStatus.clear;

    final (label, icon, bg, fg) = switch (status) {
      _TradingStatus.clear => (
        'CLEAR TO TRADE',
        Icons.check_circle_outline,
        AppColors.profitDim,
        AppColors.profit,
      ),
      _TradingStatus.journalPending => (
        'JOURNAL PENDING — log today\'s session',
        Icons.edit_note_outlined,
        AppColors.signalDim,
        AppColors.signal,
      ),
      _TradingStatus.blocked => (
        'BLOCKED — discipline score too low',
        Icons.block_outlined,
        AppColors.lossDim,
        AppColors.loss,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bg,
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.body(
              12,
              weight: FontWeight.w600,
            ).copyWith(color: fg, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}
