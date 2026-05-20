import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      // Apply after first frame so the notifier is fully initialised
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
        // Skip the selector and go straight to the pre-filled planner form
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
      appBar: AppBar(title: const Text("Select Strategy"), elevation: 0),
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
                    color: const Color(0xFF0D1A14),
                    border: Border.all(color: const Color(0x2200FF88)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 16,
                        color: Color(0xFF00FF88),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pre-filled from Signal Engine · ${preset.ticker}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF00FF88),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              preset.signalSummary,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                "Choose Your Objective",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                "Start with intent. Risk comes first.",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 24),

              // Income Strategies
              const Text(
                "Income",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StrategyTile(
                name: "Cash-Secured Put",
                category: "Income",
                color: Colors.greenAccent,
                onTap: () {
                  planner.setStrategy(
                    "csp",
                    "Cash-Secured Put",
                    "Sell a put and set aside cash for assignment.",
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed("trade_planner");
                },
              ),
              StrategyTile(
                name: "Covered Call",
                category: "Income",
                color: Colors.greenAccent,
                onTap: () {
                  planner.setStrategy(
                    "cc",
                    "Covered Call",
                    "Sell a call against shares you already own.",
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed("trade_planner");
                },
              ),
              StrategyTile(
                name: "Credit Spread",
                category: "Income",
                color: Colors.greenAccent,
                onTap: () {
                  planner.setStrategy(
                    "credit_spread",
                    "Credit Spread",
                    "Sell a put and buy a lower strike put to define risk.",
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed("trade_planner");
                },
              ),

              const SizedBox(height: 24),

              // Hedging Strategies
              const Text(
                "Hedging",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StrategyTile(
                name: "Protective Put",
                category: "Hedging",
                color: Colors.yellowAccent,
                onTap: () {
                  planner.setStrategy(
                    "protective_put",
                    "Protective Put",
                    "Buy a put to limit downside risk.",
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed("trade_planner");
                },
              ),
              StrategyTile(
                name: "Collar",
                category: "Hedging",
                color: Colors.yellowAccent,
                onTap: () {
                  planner.setStrategy(
                    "collar",
                    "Collar",
                    "Sell a call and buy a put to cap upside and limit downside.",
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed("trade_planner");
                },
              ),

              const SizedBox(height: 24),

              // Speculation Strategies
              const Text(
                "Speculation",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StrategyTile(
                name: "Long Call",
                category: "Speculation",
                color: Colors.blueAccent,
                onTap: () {
                  planner.setStrategy(
                    "long_call",
                    "Long Call",
                    "Buy a call for directional upside exposure.",
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed("trade_planner");
                },
              ),
              StrategyTile(
                name: "Long Put",
                category: "Speculation",
                color: Colors.blueAccent,
                onTap: () {
                  planner.setStrategy(
                    "long_put",
                    "Long Put",
                    "Buy a put for directional downside exposure.",
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed("trade_planner");
                },
              ),
              StrategyTile(
                name: "Debit Spread",
                category: "Speculation",
                color: Colors.blueAccent,
                onTap: () {
                  planner.setStrategy(
                    "debit_spread",
                    "Debit Spread",
                    "Buy a call and sell a higher strike call to reduce cost.",
                    symbol: symbolFromUrl,
                  );
                  context.pushNamed("trade_planner");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
