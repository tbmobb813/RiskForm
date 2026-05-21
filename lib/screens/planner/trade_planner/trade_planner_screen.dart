import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riskform/app.dart';
import '../../../state/planner_notifier.dart';
import '../components/input_section.dart';
import '../components/optional_inputs_section.dart';
import '../components/account_context_card.dart';
import '../components/hints_section.dart';
import '../components/recommended_range_slider.dart';
import '../components/input_summary_card.dart';
import '../components/greeks_panel.dart';
import '../../../services/strategy/strategy_health_service.dart';

class TradePlannerScreen extends ConsumerWidget {
  const TradePlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerNotifierProvider);
    final planner = ref.read(plannerNotifierProvider.notifier);

    if (state.strategyId == null) {
      return const Scaffold(body: Center(child: Text('No strategy selected.')));
    }

    final strategyColor = StrategyTheme.color(state.strategyId);

    return Scaffold(
      appBar: AppBar(title: Text(state.strategyName ?? 'Trade Planner')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Strategy header ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: strategyColor, width: 3),
                    top: const BorderSide(color: AppColors.border),
                    right: const BorderSide(color: AppColors.border),
                    bottom: const BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: strategyColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        StrategyTheme.badge(state.strategyId),
                        style: AppTextStyles.mono(11, color: strategyColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.strategyName!,
                            style: AppTextStyles.body(
                              15,
                              weight: FontWeight.w600,
                            ),
                          ),
                          if (state.strategyDescription != null)
                            Text(
                              state.strategyDescription!,
                              style: AppTextStyles.body(
                                12,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Greeks panel ─────────────────────────────────────────────
              GreeksPanel(delta: state.inputs?.delta),

              const SizedBox(height: 16),

              // ── Strategy health ──────────────────────────────────────────
              Builder(
                builder: (context) {
                  final health = StrategyHealthService().compute(
                    inputs: state.inputs,
                    payoff: state.payoff,
                  );
                  final pct = health.overall;
                  final color = pct >= 0.7
                      ? AppColors.profit
                      : pct >= 0.4
                      ? AppColors.signal
                      : AppColors.loss;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Strategy Health',
                                style: AppTextStyles.body(
                                  13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(pct * 100).toStringAsFixed(0)}% overall',
                                style: AppTextStyles.mono(12, color: color),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: pct,
                            color: color,
                            backgroundColor: AppColors.border,
                            strokeWidth: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Account context ──────────────────────────────────────────
              const AccountContextCard(),
              const SizedBox(height: 20),

              // ── Required inputs ──────────────────────────────────────────
              InputSection(
                strategyId: state.strategyId!,
                onInputsChanged: planner.updateInputs,
              ),

              const SizedBox(height: 12),
              const RecommendedRangeSlider(field: 'delta', min: 0.0, max: 1.0),
              const SizedBox(height: 12),
              const RecommendedRangeSlider(field: 'dte', min: 1.0, max: 120.0),
              const SizedBox(height: 12),
              const RecommendedRangeSlider(
                field: 'width',
                min: 1.0,
                max: 100.0,
              ),
              const SizedBox(height: 12),
              const InputSummaryCard(),
              const SizedBox(height: 12),
              const HintsSection(),
              const SizedBox(height: 16),

              // ── Optional inputs ──────────────────────────────────────────
              OptionalInputsSection(onNotesChanged: (_) {}),
              const SizedBox(height: 24),

              // ── CTA ──────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: strategyColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: state.inputs == null
                      ? null
                      : () async {
                          final ok = await planner.computePayoff();
                          if (!ok) return;
                          if (!context.mounted) return;
                          context.pushNamed('payoff');
                        },
                  child: const Text('Review Payoff & Risk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
