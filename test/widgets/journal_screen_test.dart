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
      timestamp: now,
      type: 'assignment',
      data: {'note': 'assigned'},
    ));

    // Debug: ensure repo contains entries before building the widget
    print('Repo entries: ${repo.getAll().length}');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: JournalScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    // Debug dump of widget tree
    debugDumpApp();

    // Two entries should be present (verify by their titles)
    final cycleFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('Cycle 0'));
    final assignmentFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('Assignment Event'));
    expect(cycleFinder, findsOneWidget);
    expect(assignmentFinder, findsOneWidget);

    // Filter to cycles only
    await tester.tap(find.text('cycle'));
    await tester.pumpAndSettle();

    // Should show single cycle tile with formatted percent (by text)
    expect(cycleFinder, findsOneWidget);

    // Navigate to detail (tap the title text)
    await tester.tap(cycleFinder);
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('cycleIndex: 0'), findsOneWidget);
  });
}
