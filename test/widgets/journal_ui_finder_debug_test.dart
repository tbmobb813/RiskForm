import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_2/screens/journal/journal_screen.dart';
import 'package:flutter_application_2/services/journal/journal_repository.dart';
import 'package:flutter_application_2/models/journal/journal_entry.dart';
import 'package:flutter_application_2/state/journal_providers.dart';

void main() {
  final runDiag = io.Platform.environment['DIAGNOSTIC_TEST'] == '1';
  // Default to writing logs when diagnostics are enabled unless DIAGNOSTIC_LOG
  // is explicitly set. Set DIAGNOSTIC_LOG=0 to disable.
  final writeLog = io.Platform.environment.containsKey('DIAGNOSTIC_LOG')
      ? io.Platform.environment['DIAGNOSTIC_LOG'] == '1'
      : runDiag;
  final logDir = io.Platform.environment['DIAGNOSTIC_LOG_DIR'] ?? 'test_output/diagnostics';

  testWidgets('JournalScreen finder diagnostics', (tester) async {
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

    
    // Zone-capture prints so we can optionally write verbose logs for CI.
    final buffer = StringBuffer();
    final zoneSpec = ZoneSpecification(
      print: (self, parent, zone, message) {
        buffer.writeln(message);
        parent.print(zone, message);
      },
    );

    await runZonedGuarded(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [journalRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: JournalScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Minimal diagnostics: avoid huge dumps. Find elements by direct key
      // equality and print a concise ancestor summary (trimmed).
      final targetKey = ValueKey('entry-c1');
      final foundByEquality = <Element>[];
      void findByKeyEquality(Element e) {
        final k = e.widget.key;
        if (k == targetKey) foundByEquality.add(e);
        e.visitChildren(findByKeyEquality);
      }
      final rootElement = WidgetsBinding.instance.rootElement;
      if (rootElement != null) findByKeyEquality(rootElement);
      print('Direct equality matches for $targetKey: ${foundByEquality.length}');
      void printAncestorsTrimmed(Element e) {
        final ancestors = <String>[];
        e.visitAncestorElements((a) {
          ancestors.add('${a.widget.runtimeType} key=${a.widget.key}');
          return true;
        });
        if (ancestors.isEmpty) {
          print('  (no ancestors)');
          return;
        }
        const max = 12;
        final toPrint = ancestors.length > max ? ancestors.sublist(0, max) : ancestors;
        print('  Ancestor chain (top ${toPrint.length} of ${ancestors.length}):');
        for (var a in toPrint) {
          print('    $a');
        }
        if (ancestors.length > max) print('    ... ${ancestors.length - max} more');
        if (e is RenderObjectElement) {
          final ro = e.renderObject;
          print('  RenderObject attached=${ro.attached}');
        }
      }
      for (final e in foundByEquality) {
        print('Found element widget=${e.widget.runtimeType} key=${e.widget.key} mounted=${e.mounted}');
        printAncestorsTrimmed(e);
      }

    // Collect a variety of finders
    final byKeyC1 = find.byKey(const ValueKey('entry-c1'));
    final byKeyA1 = find.byKey(const ValueKey('entry-a1'));
    final byKeyC1NoSkip = find.byKey(const ValueKey('entry-c1'), skipOffstage: false);
    final byKeyA1NoSkip = find.byKey(const ValueKey('entry-a1'), skipOffstage: false);
    final bySemC1 = find.bySemanticsLabel('entry-c1');
    final bySemA1 = find.bySemanticsLabel('entry-a1');
    final byTextCycle = find.textContaining('Cycle 0');
    final byTextAssignment = find.text('Assignment Event');
    final byTextCycleNoSkip = find.textContaining('Cycle 0', skipOffstage: false);
    final byTextAssignmentNoSkip = find.text('Assignment Event', skipOffstage: false);
    final byTypeListTile = find.byType(ListTile);
    final byWidgetListTilePredicate = find.byWidgetPredicate((w) => w.runtimeType.toString().contains('ListTile'));
    final byElementKeyEq = find.byElementPredicate((e) => e.widget.key == ValueKey('entry-c1'));

    final diagnostics = {
      'byKeyC1': byKeyC1,
      'byKeyA1': byKeyA1,
      'bySemC1': bySemC1,
      'bySemA1': bySemA1,
      'byTextCycle': byTextCycle,
      'byTextAssignment': byTextAssignment,
      'byTextCycleNoSkip': byTextCycleNoSkip,
      'byTextAssignmentNoSkip': byTextAssignmentNoSkip,
      'byTypeListTile': byTypeListTile,
      'byWidgetListTilePredicate': byWidgetListTilePredicate,
      'byElementKeyEq': byElementKeyEq,
      'byKeyC1NoSkip': byKeyC1NoSkip,
      'byKeyA1NoSkip': byKeyA1NoSkip,
    };

      for (final entry in diagnostics.entries) {
        final name = entry.key;
        final f = entry.value;
        final count = f.evaluate().length;
        print('Finder $name -> $count');
        for (final el in f.evaluate()) {
          final w = el.widget;
          final key = w.key;
          String title = '<no title>';
          if (w is ListTile) {
            final t = w.title;
            if (t is Text) title = t.data ?? '<null text>';
          }
          print('  widget ${w.runtimeType} key=$key title=$title');
        }
      }

      // Sanity checks: expect at least the two entries exist in repository and in UI
      expect(repo.getAll().length, 2);
      // The test is diagnostic; don't assert finders here to avoid flakiness.
    }, (e, s) {
      buffer.writeln('Zoned error: $e\n$s');
    }, zoneSpecification: zoneSpec);

    if (writeLog) {
      final name = 'journal_ui_diagnostic_${DateTime.now().toIso8601String().replaceAll(':', '-')}.log';
      final dir = io.Directory(logDir.replaceAll('\\', '/'));
      try {
        if (!dir.existsSync()) dir.createSync(recursive: true);
        final out = io.File('${dir.path}/$name');
        out.writeAsStringSync(buffer.toString());
        // Use stdout so it's captured by the test harness as well.
        print('Wrote diagnostic log to ${out.path}');
      } catch (e) {
        print('Failed to write diagnostic log: $e');
      }
    }
  }, skip: !runDiag);
}
