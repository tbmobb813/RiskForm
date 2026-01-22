import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'components/next_strategy_card.dart';
import 'components/mode_selector_card.dart';
import 'components/active_wheel_cycle_card.dart';
import 'components/risk_exposure_card.dart';
import 'components/backtest_results_card.dart';
import 'active_positions_section.dart';
import 'account_snapshot_card.dart';
import 'tools_and_strategy_library.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ModeSelectorCard(),
              SizedBox(height: 16),
              NextStrategyCard(),
              SizedBox(height: 16),
              ActiveWheelCycleCard(),
              SizedBox(height: 16),
              RiskExposureCard(),
              SizedBox(height: 16),
              BacktestResultsCard(),
              SizedBox(height: 16),
              ActivePositionsSection(),
              SizedBox(height: 16),
              AccountSnapshotCard(),
              SizedBox(height: 16),
              // Behavior Dashboard quick access
              _BehaviorTile(),
              SizedBox(height: 16),
              ToolsAndStrategyLibrary(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BehaviorTile extends StatelessWidget {
  const _BehaviorTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Behavior Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Track your discipline trend, streaks, and recent trades.'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.goNamed('behavior'),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}