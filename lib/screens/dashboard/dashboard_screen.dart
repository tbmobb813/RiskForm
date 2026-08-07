import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riskform/app.dart';
import 'components/hero_stats_zone.dart';
import 'components/next_strategy_card.dart';
import 'components/active_wheel_cycle_card.dart';
import 'components/risk_exposure_card.dart';
import 'components/backtest_results_card.dart';
import 'components/status_banner.dart';
import 'active_positions_section.dart';
import 'package:riskform/services/firebase/auth_service.dart';
import 'package:riskform/screens/settings/settings_screen.dart';
import 'package:riskform/state/strategy_controller.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/small_account_dashboard.dart'
    show SmallAccountDashboardBody;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(strategyControllerProvider);
    final ctl = ref.read(strategyControllerProvider.notifier);
    final isSignedIn = ref.watch(currentUserIdProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RiskForm'),
        actions: [
          IconButton(
            tooltip: isSignedIn ? 'Account' : 'Sign in to save your plans',
            icon: Icon(
              isSignedIn
                  ? Icons.account_circle
                  : Icons.account_circle_outlined,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<AccountMode>(
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.surface2,
                selectedBackgroundColor: AppColors.primaryDim,
                selectedForegroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.textMuted,
                side: const BorderSide(color: AppColors.border),
                textStyle: AppTextStyles.body(12, weight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(
                  value: AccountMode.smallAccount,
                  label: Text('Small'),
                ),
                ButtonSegment(value: AccountMode.wheel, label: Text('Wheel')),
              ],
              selected: {state.mode},
              onSelectionChanged: (s) => ctl.setMode(s.first),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const StatusBanner(),
          const HeroStatsZone(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: state.mode == AccountMode.smallAccount
                    ? const _SmallAccountContent(key: ValueKey('small'))
                    : const _WheelContent(key: ValueKey('wheel')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAccountContent extends StatelessWidget {
  const _SmallAccountContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _stagger([
        const SmallAccountDashboardBody(),
        const _BehaviorTile(),
      ]),
    );
  }
}

class _WheelContent extends StatelessWidget {
  const _WheelContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _stagger([
        const NextStrategyCard(),
        const ActiveWheelCycleCard(),
        const RiskExposureCard(),
        const BacktestResultsCard(),
        const ActivePositionsSection(),
        const _BehaviorTile(),
      ]),
    );
  }
}

/// Wraps each widget in a staggered fade + slide-up effect.
List<Widget> _stagger(List<Widget> children) {
  const baseDelay = 60;
  const slidePx = 18.0;

  final result = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    result.add(
      children[i]
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: baseDelay * i),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          )
          .slideY(
            begin: slidePx / 100,
            end: 0,
            delay: Duration(milliseconds: baseDelay * i),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          ),
    );
    if (i < children.length - 1) {
      result.add(const SizedBox(height: 16));
    }
  }
  return result;
}

class _BehaviorTile extends StatelessWidget {
  const _BehaviorTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Behavior Dashboard',
                    style: AppTextStyles.body(14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discipline trends, streaks & habits',
                    style: AppTextStyles.body(
                      12,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => context.goNamed('behavior'),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}
