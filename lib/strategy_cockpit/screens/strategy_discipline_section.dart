import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/strategy_discipline_viewmodel.dart';
import '../widgets/strategy_section_container.dart';

class StrategyDisciplineSection extends StatelessWidget {
  final String strategyId;
  final StrategyDisciplineViewModel? viewModel;

  const StrategyDisciplineSection({
    super.key,
    required this.strategyId,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return viewModel != null
        ? ChangeNotifierProvider.value(
            value: viewModel!,
            child: Consumer<StrategyDisciplineViewModel>(
              builder: (context, vm, _) => _buildForVm(vm),
            ),
          )
        : ChangeNotifierProvider<StrategyDisciplineViewModel>(
            create: (_) => StrategyDisciplineViewModel(strategyId: strategyId),
            child: Consumer<StrategyDisciplineViewModel>(
              builder: (context, vm, _) => _buildForVm(vm),
            ),
          );
  }

  Widget _buildForVm(StrategyDisciplineViewModel vm) {
    if (vm.isLoading) {
      return const StrategySectionContainer(
        title: 'Discipline',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.hasError) {
      return const StrategySectionContainer(
        title: 'Discipline',
        child: Center(child: Text('Unable to load discipline data')),
      );
    }

    return StrategySectionContainer(
      title: 'Discipline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discipline Trend Sparkline
          _DisciplineSparkline(values: vm.disciplineTrend),
          const SizedBox(height: 16),

          // Violations Breakdown
          _ViolationsBreakdown(breakdown: vm.violationBreakdown),
          const SizedBox(height: 16),

          // Streak Indicators
          _StreakRow(
            clean: vm.cleanCycleStreak,
            adherence: vm.adherenceStreak,
            risk: vm.riskStreak,
          ),
          const SizedBox(height: 16),

          // Recent Discipline Events
          _RecentEventsList(events: vm.recentEvents),
        ],
      ),
    );
  }
}

class _DisciplineSparkline extends StatelessWidget {
  final List<double> values;

  const _DisciplineSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discipline Trend', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          alignment: Alignment.center,
          child: Text(
            values.isEmpty ? 'No data yet' : 'Sparkline (${values.length} points)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ViolationsBreakdown extends StatelessWidget {
  final Map<String, int> breakdown;

  const _ViolationsBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final adherence = breakdown['adherence'] ?? 0;
    final timing = breakdown['timing'] ?? 0;
    final risk = breakdown['risk'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Violations Breakdown', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ViolationTile(label: 'Adherence', count: adherence)),
            const SizedBox(width: 8),
            Expanded(child: _ViolationTile(label: 'Timing', count: timing)),
            const SizedBox(width: 8),
            Expanded(child: _ViolationTile(label: 'Risk', count: risk)),
          ],
        ),
      ],
    );
  }
}

class _ViolationTile extends StatelessWidget {
  final String label;
  final int count;

  const _ViolationTile({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(count.toString(), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  final int clean;
  final int adherence;
  final int risk;

  const _StreakRow({required this.clean, required this.adherence, required this.risk});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StreakCard(label: 'Clean Cycles', value: clean)),
        const SizedBox(width: 8),
        Expanded(child: _StreakCard(label: 'Adherence', value: adherence)),
        const SizedBox(width: 8),
        Expanded(child: _StreakCard(label: 'Risk', value: risk)),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String label;
  final int value;

  const _StreakCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value.toString(), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _RecentEventsList extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  const _RecentEventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text('No recent discipline events');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Discipline Events', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...events.map((e) => _EventTile(event: e)),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final label = event['label'] ?? event['id'] ?? 'Cycle';
    final score = (event['disciplineScore'] ?? 0).toDouble();

    return Card(
      elevation: 0,
      child: ListTile(
        title: Text(label.toString()),
        subtitle: Text('Discipline Score: ${score.toStringAsFixed(1)}'),
      ),
    );
  }
}
