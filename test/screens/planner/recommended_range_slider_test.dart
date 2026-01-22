import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/state/planner_state.dart';
import 'package:riskform/strategy_cockpit/analytics/regime_aware_planner_hints.dart' as planner_hints;
import 'package:riskform/screens/planner/components/recommended_range_slider.dart';

void main() {
  testWidgets('RecommendedRangeSlider shows recommended range from provider', (tester) async {
    final ranges = <String, RangeValues>{'delta': const RangeValues(0.15, 0.20)};
    final bundle = planner_hints.PlannerHintBundle(hints: const [], recommendedRanges: ranges);
    final state = PlannerState.initial().copyWith(hintsBundle: bundle);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: Scaffold(body: RecommendedRangeSlider(field: 'delta', min: 0.0, max: 1.0, initialState: state)))),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Recommended DELTA'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
    expect(find.textContaining('0.15'), findsOneWidget);
    expect(find.textContaining('0.20'), findsOneWidget);
  });
}

// No fake notifier required; the widget supports an injected initialState for tests.
