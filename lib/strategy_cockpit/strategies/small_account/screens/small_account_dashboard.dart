import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riskform/app.dart';
import 'package:riskform/state/strategy_controller.dart';

// Simple account providers (placeholders already present elsewhere in the app)
import 'package:riskform/state/account_providers.dart';
import 'package:riskform/strategy_cockpit/strategies/trading_strategy.dart';

class SmallAccountDashboard extends ConsumerWidget {
  const SmallAccountDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Small Account Mode')),
      body: const SmallAccountDashboardBody(),
    );
  }
}

class SmallAccountDashboardBody extends ConsumerWidget {
  const SmallAccountDashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(strategyControllerProvider);
    final strategy = state.strategy;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AccountSnapshotCard(),
          const SizedBox(height: 24),

          const ToolsSection(),
          const SizedBox(height: 24),

          ActiveStrategySection(strategy: strategy),
        ],
      ),
    );
  }
}

class AccountSnapshotCard extends ConsumerWidget {
  const AccountSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(accountBalanceProvider);
    final riskDeployed = ref.watch(riskDeployedProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Snapshot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Text('Balance: \$${balance.toStringAsFixed(2)}'),
            Text('Risk Deployed: \$${riskDeployed.toStringAsFixed(2)}'),
            Text(
              'Available Risk: \$${(balance - riskDeployed).toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }
}

class ToolsSection extends ConsumerStatefulWidget {
  const ToolsSection({super.key});

  @override
  ConsumerState<ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends ConsumerState<ToolsSection> {
  Future<String?> _promptTicker() async {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Ticker'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(hintText: 'e.g. SPY'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctl.text.trim()),
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tools', style: AppTextStyles.display(18)),
        const SizedBox(height: 12),

        ToolCard(
          title: 'Cheap Options Scanner',
          subtitle: 'Find affordable long calls and puts',
          icon: Icons.search,
          color: AppColors.primary,
          index: 0,
          onTap: () async {
            final ticker = await _promptTicker();
            if (!mounted) return;
            if (ticker == null || ticker.isEmpty) return;
            // ignore: use_build_context_synchronously
            context.pushNamed(
              'small_account_scanner',
              pathParameters: {'ticker': ticker},
            );
          },
        ),

        const SizedBox(height: 12),

        ToolCard(
          title: 'Debit Spread Builder',
          subtitle: 'Build defined-risk bullish spreads',
          icon: Icons.timeline,
          color: AppColors.signal,
          index: 1,
          onTap: () async {
            final ticker = await _promptTicker();
            if (!mounted) return;
            if (ticker == null || ticker.isEmpty) return;
            // ignore: use_build_context_synchronously
            context.pushNamed(
              'small_account_spread_builder',
              pathParameters: {'ticker': ticker},
            );
          },
        ),

        const SizedBox(height: 12),

        ToolCard(
          title: 'Regime Replay',
          subtitle: 'Replay a Wheel campaign through a historical regime',
          icon: Icons.history,
          color: AppColors.profit,
          index: 2,
          onTap: () => context.pushNamed('regime_replay'),
        ),
      ],
    );
  }
}

// No-op helper here; routes will accept an OptionsChainService via navigation `extra` if callers provide one.

class ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final int index;

  const ToolCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = AppColors.primary,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: AppTextStyles.body(14, weight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.body(12).copyWith(color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
      ),
    ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        ).slideY(
          begin: 0.18,
          end: 0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
  }
}

class ActiveStrategySection extends ConsumerWidget {
  final TradingStrategy? strategy;

  const ActiveStrategySection({super.key, required this.strategy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (strategy == null) {
      return const Text('No active strategy selected');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Strategy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Text(strategy!.label, style: const TextStyle(fontSize: 16)),
            Text('Breakeven: ${strategy!.breakeven.toStringAsFixed(2)}'),
            Text('Max Risk: \$${strategy!.maxRisk.toStringAsFixed(2)}'),
            Text(
              'Max Profit: ${strategy!.maxProfit.isInfinite ? "∞" : "\$${strategy!.maxProfit.toStringAsFixed(2)}"}',
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () =>
                  context.pushNamed('small_account_strategy_dashboard'),
              child: const Text('Open Strategy Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
