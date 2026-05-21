import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riskform/app.dart';
import '../../../models/signal_planner_preset.dart';
import '../../../state/planner_notifier.dart';
import '../../dashboard/strategy_tile.dart';

class StrategySelectorScreen extends ConsumerStatefulWidget {
  final String? preselectedStrategyId;
  final SignalPlannerPreset? preset;

  const StrategySelectorScreen({
    super.key,
    this.preselectedStrategyId,
    this.preset,
  });

  @override
  ConsumerState<StrategySelectorScreen> createState() =>
      _StrategySelectorScreenState();
}

class _StrategySelectorScreenState
    extends ConsumerState<StrategySelectorScreen> {
  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    if (preset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final planner = ref.read(plannerNotifierProvider.notifier);
        planner.setStrategy(
          preset.strategyId,
          preset.strategyName,
          preset.strategyDescription,
          symbol: preset.ticker,
        );
        planner.updateInputs(preset.inputs);
        context.pushNamed('trade_planner');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.read(plannerNotifierProvider.notifier);
    final symbolFromUrl = Uri.base.queryParameters['symbol']
        ?.toString()
        .toUpperCase();
    final preset = widget.preset;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Strategy')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Signal Engine pre-fill banner
              if (preset != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.signalDim,
                    border: Border.all(color: AppColors.signal.withAlpha(60)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, size: 16, color: AppColors.signal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pre-filled from Signal Engine · ${preset.ticker}',
                              style: AppTextStyles.body(
                                11,
                                weight: FontWeight.w600,
                              ).copyWith(color: AppColors.signal),
                            ),
                            Text(
                              preset.signalSummary,
                              style: AppTextStyles.body(
                                10,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text('Choose Your Objective', style: AppTextStyles.display(20)),
              const SizedBox(height: 4),
              Text(
                'Start with intent. Risk comes first.',
                style: AppTextStyles.body(
                  13,
                ).copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              _SectionHeader('Income'),
              const SizedBox(height: 8),
              StrategyTile(
                name: 'Cash-Secured Put',
                strategyId: 'csp',
                onTap: () {
                  planner.setStrategy(
                    'csp',
                    'Cash-Secured Put',
                    'Sell a put and set aside cash for assignment.',
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed('trade_planner');
                },
              ),
              const SizedBox(height: 8),
              StrategyTile(
                name: 'Covered Call',
                strategyId: 'cc',
                onTap: () {
                  planner.setStrategy(
                    'cc',
                    'Covered Call',
                    'Sell a call against shares you already own.',
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed('trade_planner');
                },
              ),
              const SizedBox(height: 8),
              StrategyTile(
                name: 'Credit Spread',
                strategyId: 'credit_spread',
                onTap: () {
                  planner.setStrategy(
                    'credit_spread',
                    'Credit Spread',
                    'Sell a put and buy a lower strike put to define risk.',
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed('trade_planner');
                },
              ),

              const SizedBox(height: 24),
              _SectionHeader('Hedging'),
              const SizedBox(height: 8),
              StrategyTile(
                name: 'Protective Put',
                strategyId: 'protective_put',
                onTap: () {
                  planner.setStrategy(
                    'protective_put',
                    'Protective Put',
                    'Buy a put to limit downside risk.',
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed('trade_planner');
                },
              ),
              const SizedBox(height: 8),
              StrategyTile(
                name: 'Collar',
                strategyId: 'collar',
                onTap: () {
                  planner.setStrategy(
                    'collar',
                    'Collar',
                    'Sell a call and buy a put to cap upside and limit downside.',
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed('trade_planner');
                },
              ),

              const SizedBox(height: 24),
              _SectionHeader('Speculation'),
              const SizedBox(height: 8),
              StrategyTile(
                name: 'Long Call',
                strategyId: 'long_call',
                onTap: () {
                  planner.setStrategy(
                    'long_call',
                    'Long Call',
                    'Buy a call for directional upside exposure.',
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed('trade_planner');
                },
              ),
              const SizedBox(height: 8),
              StrategyTile(
                name: 'Long Put',
                strategyId: 'long_put',
                onTap: () {
                  planner.setStrategy(
                    'long_put',
                    'Long Put',
                    'Buy a put for directional downside exposure.',
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed('trade_planner');
                },
              ),
              const SizedBox(height: 8),
              StrategyTile(
                name: 'Debit Spread',
                strategyId: 'debit_spread',
                onTap: () {
                  planner.setStrategy(
                    'debit_spread',
                    'Debit Spread',
                    'Buy a call and sell a higher strike call to reduce cost.',
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed('trade_planner');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.body(
        11,
        weight: FontWeight.w700,
      ).copyWith(color: AppColors.textMuted, letterSpacing: 1.2),
    );
  }
}
