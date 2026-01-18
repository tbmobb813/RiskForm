import 'dart:math';

import '../../models/backtest/backtest_result.dart';
import '../../models/journal/journal_entry.dart';
import 'journal_repository.dart';

class JournalAutomationService {
  final JournalRepository repo;
  final Random _secureRandom = Random.secure();

  JournalAutomationService({required this.repo});

  // Generate a more robust ID using secure random and timestamp
  String _id() => '${DateTime.now().microsecondsSinceEpoch}-${_secureRandom.nextInt(0x7FFFFFFF)}';

  Future<void> recordBacktest(BacktestResult result) async {
    final entry = JournalEntry(
      id: _id(),
      timestamp: DateTime.now(),
      type: 'backtest',
      data: {
        'totalReturn': result.totalReturn,
        'maxDrawdown': result.maxDrawdown,
        'cyclesCompleted': result.cyclesCompleted,
        'avgCycleReturn': result.avgCycleReturn,
        'assignmentRate': result.assignmentRate,
      },
    );

    await repo.addEntry(entry);
  }

  Future<void> recordCycle(CycleStats cycle) async {
    final entry = JournalEntry(
      id: _id(),
      timestamp: DateTime.now(),
      type: 'cycle',
      data: {
        'cycleIndex': cycle.index,
        'cycleReturn': cycle.cycleReturn,
        'durationDays': cycle.durationDays,
        'hadAssignment': cycle.hadAssignment,
        'dominantRegime': cycle.dominantRegime?.toString(),
      },
    );

    await repo.addEntry(entry);
  }

  Future<void> recordAssignment(CycleStats cycle) async {
    final entry = JournalEntry(
      id: _id(),
      timestamp: DateTime.now(),
      type: 'assignment',
      data: {
        'cycleIndex': cycle.index,
        'costBasis': cycle.startEquity,
        'regime': cycle.dominantRegime?.toString(),
      },
    );

    await repo.addEntry(entry);
  }

  Future<void> recordCalledAway(CycleStats cycle) async {
    final entry = JournalEntry(
      id: _id(),
      timestamp: DateTime.now(),
      type: 'calledAway',
      data: {
        'cycleIndex': cycle.index,
        'endEquity': cycle.endEquity,
        'regime': cycle.dominantRegime?.toString(),
      },
    );

    await repo.addEntry(entry);
  }
}
