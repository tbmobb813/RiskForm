import 'package:flutter/material.dart';

import '../viewmodels/strategy_cockpit_viewmodel.dart';
import '../widgets/strategy_section_container.dart';
import 'strategy_performance_section.dart';
import 'strategy_discipline_section.dart';
import 'strategy_regime_section.dart';
import 'strategy_backtest_section.dart';
import 'strategy_actions_section.dart';

class StrategyCockpitScreen extends StatefulWidget {
  final String strategyId;
  final StrategyCockpitViewModel? viewModel;

  const StrategyCockpitScreen({super.key, required this.strategyId, this.viewModel});

  @override
  State<StrategyCockpitScreen> createState() => _StrategyCockpitScreenState();
}

class _StrategyCockpitScreenState extends State<StrategyCockpitScreen> {
  late final StrategyCockpitViewModel _vm;
  late final bool _ownsVm;

  @override
  void initState() {
    super.initState();
    _vm = widget.viewModel ?? StrategyCockpitViewModel(strategyId: widget.strategyId);
    _ownsVm = widget.viewModel == null;
    _vm.addListener(_onVmChanged);
  }

  void _onVmChanged() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    if (_ownsVm) _vm.dispose();
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
            StrategyPerformanceSection(strategyId: widget.strategyId, viewModel: null),

            // Discipline
            StrategyDisciplineSection(strategyId: widget.strategyId, viewModel: null),

            // Regime
            StrategyRegimeSection(strategyId: widget.strategyId, viewModel: null),

            // Backtests
            StrategyBacktestSection(strategyId: widget.strategyId, viewModel: null),

            // Actions
            StrategyActionsSection(strategyId: widget.strategyId, viewModel: _vm),
          ],
        ),
      ),
    );
  }
}
