import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/screens/planner/risk_summary/risk_metrics_card.dart';
import 'package:flutter_application_2/models/risk_result.dart';

void main() {
  testWidgets('RiskMetricsCard displays metrics correctly', (WidgetTester tester) async {
    final risk = RiskResult(riskPercentOfAccount: 7.5, assignmentExposure: true, capitalLocked: 400.0, warnings: ['w']);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RiskMetricsCard(risk: risk))));

    expect(find.text('Risk Metrics'), findsOneWidget);
    expect(find.text('7.5%'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text(r"$400.00"), findsOneWidget);
  });

  testWidgets('RiskMetricsCard displays labels and values', (WidgetTester tester) async {
    final risk = RiskResult(
      riskPercentOfAccount: 3.5,
      assignmentExposure: true,
      capitalLocked: 1234.56,
      warnings: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RiskMetricsCard(risk: risk)),
      ),
    );

    expect(find.text('Risk Metrics'), findsOneWidget);
    expect(find.text('Risk % of Account'), findsOneWidget);
    expect(find.text('3.5%'), findsOneWidget);
    expect(find.text('Assignment Exposure'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('Capital Locked'), findsOneWidget);
    expect(find.textContaining('1234.56'), findsOneWidget);
  });
}
