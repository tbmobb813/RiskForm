import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/state/strategy_controller.dart';
// Navigation uses named routes; concrete screens are constructed via router with extras when needed.

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
            const Text('Account Snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Text('Balance: \$${balance.toStringAsFixed(2)}'),
            Text('Risk Deployed: \$${riskDeployed.toStringAsFixed(2)}'),
            Text('Available Risk: \$${(balance - riskDeployed).toStringAsFixed(2)}'),
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
        content: TextField(controller: ctl, decoration: const InputDecoration(hintText: 'e.g. SPY')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctl.text.trim()), child: const Text('Go')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        ToolCard(
          title: 'Cheap Options Scanner',
          subtitle: 'Find affordable long calls and puts',
          icon: Icons.search,
          onTap: () async {
            final ticker = await _promptTicker();
            if (!mounted) return;
            if (ticker == null || ticker.isEmpty) return;
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushNamed('/small_account/scanner/$ticker');
          },
        ),

        const SizedBox(height: 12),

        ToolCard(
          title: 'Debit Spread Builder',
          subtitle: 'Build defined-risk bullish spreads',
          icon: Icons.timeline,
          onTap: () async {
            final ticker = await _promptTicker();
            if (!mounted) return;
            if (ticker == null || ticker.isEmpty) return;
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushNamed('/small_account/spread_builder/$ticker');
          },
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

  const ToolCard({super.key, required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
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
            const Text('Active Strategy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Text(strategy!.label, style: const TextStyle(fontSize: 16)),
            Text('Breakeven: ${strategy!.breakeven.toStringAsFixed(2)}'),
            Text('Max Risk: \$${strategy!.maxRisk.toStringAsFixed(2)}'),
            Text('Max Profit: ${strategy!.maxProfit.isInfinite ? "∞" : "\$${strategy!.maxProfit.toStringAsFixed(2)}"}'),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/small_account/strategy_dashboard'),
              child: const Text('Open Strategy Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
