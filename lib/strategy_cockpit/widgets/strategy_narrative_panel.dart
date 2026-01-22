import 'package:flutter/material.dart';
import '../viewmodels/strategy_cockpit_viewmodel.dart';
import '../analytics/strategy_narrative_engine.dart';
import '../analytics/strategy_recommendations_engine.dart';

class StrategyNarrativePanel extends StatelessWidget {
  final StrategyCockpitViewModel vm;

  const StrategyNarrativePanel({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.strategy == null || vm.health == null) return const SizedBox.shrink();

    // Build StrategyContext from vm (best-effort)
    final c = vm.health!;

    final constraintsMap = vm.strategy!.constraints;
    final constraints = Constraints(
      maxRisk: (constraintsMap['maxRisk'] is int) ? constraintsMap['maxRisk'] as int : 100,
      maxPositions: (constraintsMap['maxPositions'] is int) ? constraintsMap['maxPositions'] as int : 5,
      allowedDteRange: constraintsMap['allowedDteRange'] is List ? List<int>.from(constraintsMap['allowedDteRange']) : null,
      allowedDeltaRange: constraintsMap['allowedDeltaRange'] is List ? List<double>.from(constraintsMap['allowedDeltaRange'].map((v) => (v as num).toDouble())) : null,
    );

    final recent = <CycleSummary>[];
    for (var i = 0; i < (c.cycleSummaries.length); i++) {
      final m = c.cycleSummaries[i];
      final ds = (m['disciplineScore'] is num) ? (m['disciplineScore'] as num).toInt() : 50;
      final pnl = (m['pnl'] is num) ? (m['pnl'] as num).toDouble() : 0.0;
      final r = (m['regime'] is String) ? m['regime'] as String : vm.currentRegime ?? 'unknown';
      recent.add(CycleSummary(disciplineScore: ds, pnl: pnl, regime: r));
    }

    final backtest = vm.latestBacktest == null
        ? null
        : BacktestSummary(bestConfig: vm.latestBacktest, weakConfig: null, summaryNote: null);

    final ctx = StrategyContext(
      healthScore: (c.healthScore ?? 50).toInt(),
      pnlTrend: List<double>.from(c.pnlTrend),
      disciplineTrend: c.disciplineTrend.map((d) => d.round()).toList(),
      recentCycles: recent,
      constraints: constraints,
      currentRegime: vm.currentRegime ?? 'unknown',
      drawdown: 0.0,
      backtestComparison: backtest,
    );

    final narrative = vm.narrative ?? generateNarrative(ctx, recsBundle: vm.recommendations);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(narrative.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(narrative.summary, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            ...narrative.bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Icon(Icons.fiber_manual_record, size: 8),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b, style: Theme.of(context).textTheme.bodySmall)),
                  ]),
                )),
            const SizedBox(height: 8),
            Text('Outlook: ${narrative.outlook}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
