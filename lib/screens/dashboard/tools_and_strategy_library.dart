import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'tool_tile.dart';
import 'strategy_tile.dart';

// Placeholder provider — replace with real Pro logic later.
final isProUserProvider = Provider<bool>((ref) => false);

class ToolsAndStrategyLibrary extends ConsumerWidget {
  const ToolsAndStrategyLibrary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProUserProvider);
    final auth = ref.watch(authServiceProvider);
    final signedIn = auth.currentUserId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tools",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Tools Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ToolTile(
              label: "Payoff Visualizer",
              icon: Icons.show_chart,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Open Payoff Visualizer")),
                );
              },
            ),
            ToolTile(
              label: "Risk Calculator",
              icon: Icons.calculate,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Open Risk Calculator")),
                );
              },
            ),
            ToolTile(
              label: "Journal",
              icon: Icons.book_outlined,
              onTap: () {
                GoRouter.of(context).pushNamed("journal");
              },
            ),
            if (signedIn)
              ToolTile(
                label: "Journal (Cloud)",
                icon: Icons.cloud_outlined,
                onTap: () {
                  GoRouter.of(context).pushNamed("journalFirestore");
                },
              ),
            if (!signedIn)
              ToolTile(
                label: "Journal (Cloud)",
                icon: Icons.cloud_outlined,
                locked: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to access cloud journal')));
                },
              ),
            ToolTile(
              label: "Wheel Tracker",
              icon: Icons.sync_alt,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Open Wheel Tracker")),
                );
              },
            ),

            // Pro-only tool
            ToolTile(
              label: "Hedge Comparison",
              icon: Icons.security,
              locked: !isPro,
              onTap: () {
                if (!isPro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pro feature")),
                  );
                  return;
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          "Strategy Library",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Income Strategies
        const Text("Income", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        StrategyTile(
          name: "Cash-Secured Put",
          category: "Income",
          color: Colors.greenAccent,
          onTap: () => GoRouter.of(context).pushNamed("planner", extra: "csp"),
        ),
        StrategyTile(
          name: "Covered Call",
          category: "Income",
          color: Colors.greenAccent,
          onTap: () => GoRouter.of(context).pushNamed("planner", extra: "cc"),
        ),
        StrategyTile(
          name: "Credit Spread",
          category: "Income",
          color: Colors.greenAccent,
          onTap: () => GoRouter.of(context).pushNamed("planner", extra: "credit_spread"),
        ),

        const SizedBox(height: 16),

        // Hedging Strategies
        const Text("Hedging", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        StrategyTile(
          name: "Protective Put",
          category: "Hedging",
          color: Colors.yellowAccent,
          onTap: () => GoRouter.of(context).pushNamed("planner", extra: "protective_put"),
        ),
        StrategyTile(
          name: "Collar",
          category: "Hedging",
          color: Colors.yellowAccent,
          onTap: () => GoRouter.of(context).pushNamed("planner", extra: "collar"),
        ),

        const SizedBox(height: 16),

        // Speculation Strategies
        const Text("Speculation", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        StrategyTile(
          name: "Long Call",
          category: "Speculation",
          color: Colors.blueAccent,
          onTap: () => GoRouter.of(context).pushNamed("planner", extra: "long_call"),
        ),
        StrategyTile(
          name: "Long Put",
          category: "Speculation",
          color: Colors.blueAccent,
          onTap: () => GoRouter.of(context).pushNamed("planner", extra: "long_put"),
        ),
        StrategyTile(
          name: "Debit Spread",
          category: "Speculation",
          color: Colors.blueAccent,
          onTap: () => GoRouter.of(context).pushNamed("planner", extra: "debit_spread"),
        ),
      ],
    );
  }
}