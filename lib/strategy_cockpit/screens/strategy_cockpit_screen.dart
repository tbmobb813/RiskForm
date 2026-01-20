import 'package:flutter/material.dart';

import '../viewmodels/strategy_cockpit_viewmodel.dart';
import '../widgets/strategy_section_container.dart';

class StrategyCockpitScreen extends StatefulWidget {
  final String strategyId;

  const StrategyCockpitScreen({super.key, required this.strategyId});

  @override
  State<StrategyCockpitScreen> createState() => _StrategyCockpitScreenState();
}

class _StrategyCockpitScreenState extends State<StrategyCockpitScreen> {
  late final StrategyCockpitViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = StrategyCockpitViewModel(strategyId: widget.strategyId);
    _vm.addListener(_onVmChanged);
  }

  void _onVmChanged() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strategyName = _vm.strategy?.name ?? widget.strategyId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cockpit — $strategyName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section (lightweight)
            StrategySectionContainer(
              title: 'Header',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strategyName, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Performance
            StrategySectionContainer(
              title: 'Performance',
              child: const SizedBox(height: 120, child: Center(child: Text('Performance Module Placeholder'))),
            ),

            // Discipline
            StrategySectionContainer(
              title: 'Discipline',
              child: const SizedBox(height: 120, child: Center(child: Text('Discipline Module Placeholder'))),
            ),

            // Regime
            StrategySectionContainer(
              title: 'Regime',
              child: const SizedBox(height: 120, child: Center(child: Text('Regime Module Placeholder'))),
            ),

            // Backtests
            StrategySectionContainer(
              title: 'Backtests',
              child: const SizedBox(height: 120, child: Center(child: Text('Backtest Module Placeholder'))),
            ),

            // Actions
            StrategySectionContainer(
              title: 'Actions',
              child: Wrap(spacing: 8.0, children: [
                ElevatedButton(onPressed: () {}, child: const Text('Open Planner')),
                OutlinedButton(onPressed: () {}, child: const Text('Run Backtest')),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
