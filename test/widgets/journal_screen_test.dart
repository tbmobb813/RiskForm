import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_2/screens/journal/journal_screen.dart';
import 'package:flutter_application_2/services/journal/journal_repository.dart';
import 'package:flutter_application_2/models/journal/journal_entry.dart';
import 'package:flutter_application_2/state/journal_providers.dart';

void main() {
  testWidgets('JournalScreen displays entries, filters, and navigates to detail', (tester) async {
    final repo = JournalRepository();
    final now = DateTime.now();

    await repo.addEntry(JournalEntry(
      id: 'c1',
      timestamp: now,
      type: 'cycle',
      data: {'cycleIndex': 0, 'cycleReturn': 0.05},
    ));

    await repo.addEntry(JournalEntry(
      id: 'a1',
      timestamp: now.add(const Duration(seconds: 1)),
      type: 'assignment',
      data: {'note': 'assigned'},
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: JournalScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to the assignment entry and verify it's visible
    final assignmentKey = ValueKey('entry-a1');
    final verticalScrollable = find.byWidgetPredicate((w) => w is Scrollable && (w as Scrollable).axisDirection == AxisDirection.down);
    await tester.scrollUntilVisible(
      find.byKey(assignmentKey),
      200.0,
      scrollable: verticalScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(assignmentKey), findsOneWidget);

    // Now filter to cycles only
    final cycleFilter = find.text('cycle');
    expect(cycleFilter, findsOneWidget);
    await tester.tap(cycleFilter);
    await tester.pumpAndSettle();

    // Scroll to the cycle entry and verify
    final cycleKey = ValueKey('entry-c1');
    await tester.scrollUntilVisible(
      find.byKey(cycleKey),
      200.0,
      scrollable: verticalScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(cycleKey), findsOneWidget);

    // Navigate to detail
    await tester.tap(find.byKey(cycleKey));
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    expect(find.textContaining('cycleIndex: 0'), findsOneWidget);
  });
}
