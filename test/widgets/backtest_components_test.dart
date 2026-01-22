import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform_core/models/backtest/backtest_result.dart' show BacktestResult, CycleStats;
import 'package:riskform_core/models/backtest/backtest_config.dart';

import 'package:riskform/screens/backtest/components/backtest_metrics_card.dart';
import 'package:riskform/screens/backtest/components/backtest_equity_chart.dart';
import 'package:riskform/screens/backtest/components/backtest_cycle_breakdown_card.dart';
import 'package:riskform/screens/backtest/components/backtest_log_list.dart';

void main() {
  BacktestResult makeResult() {
    final config = BacktestConfig(
      startingCapital: 10000,
      maxCycles: 5,
      pricePath: [100, 105, 110],
      strategyId: 'stratA',
      symbol: 'ABC',
      startDate: DateTime(2020, 1, 1),
      endDate: DateTime(2020, 12, 31),
    );

    final cycles = [
      CycleStats(
        cycleId: 'c1',
        index: 0,
        startEquity: 10000,
        endEquity: 10200,
        durationDays: 30,
        hadAssignment: false,
      ),
      CycleStats(
        cycleId: 'c2',
        index: 1,
        startEquity: 10200,
        endEquity: 10100,
        durationDays: 28,
        hadAssignment: true,
      ),
    ];

    return BacktestResult(
      configUsed: config,
      equityCurve: [10000.0, 10200.0, 10100.0],
      maxDrawdown: 0.02,
      totalReturn: 0.01,
      cyclesCompleted: cycles.length,
      notes: ['Started', 'Completed cycle 1', 'Completed cycle 2'],
      cycles: cycles,
      avgCycleReturn: 0.005,
      avgCycleDurationDays: 29.0,
      assignmentRate: 0.5,
      uptrendAvgCycleReturn: 0.01,
      downtrendAvgCycleReturn: -0.01,
      sidewaysAvgCycleReturn: 0.002,
      uptrendAssignmentRate: 0.5,
      downtrendAssignmentRate: 0.4,
      sidewaysAssignmentRate: 0.3,
    );
  }

  testWidgets('BacktestMetricsCard displays metrics', (tester) async {
    final result = makeResult();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BacktestMetricsCard(result: result))));

    expect(find.text('Performance Summary'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
    expect(find.text('Cycles completed', skipOffstage: false), findsNothing);
  });

  testWidgets('BacktestEquityChart builds', (tester) async {
    final result = makeResult();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BacktestEquityChart(result: result))));

    expect(find.text('Equity Curve'), findsOneWidget);
  });

  testWidgets('CycleBreakdownCard shows cycles', (tester) async {
    final result = makeResult();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CycleBreakdownCard(cycles: result.cycles))));

    expect(find.text('Cycle Breakdown'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(result.cycles.length));
  });

  testWidgets('BacktestLogList shows steps', (tester) async {
    final result = makeResult();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BacktestLogList(steps: result.notes))));

    expect(find.text('Backtest Log'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.textContaining('Completed cycle 1'), findsOneWidget);
  });
}
