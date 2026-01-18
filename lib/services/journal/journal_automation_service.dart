import 'package:uuid/uuid.dart';

import '../../models/backtest/backtest_result.dart';
import '../../models/journal/journal_entry.dart';
import 'journal_repository.dart';

class JournalAutomationService {
  final JournalRepository repo;
  static const _uuid = Uuid();

  JournalAutomationService({required this.repo});

  Future<void> recordBacktest(BacktestResult result) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: 'backtest',
      data: {
        'symbol': result.configUsed.symbol,
        'label': result.configUsed.label,
        'totalReturn': result.totalReturn,
        'maxDrawdown': result.maxDrawdown,
        'cyclesCompleted': result.cyclesCompleted,
        'avgCycleReturn': result.avgCycleReturn,
        'assignmentRate': result.assignmentRate,
      },
    );

    await repo.addEntry(entry);
  }

  Future<void> recordCycle(CycleStats cycle, String symbol) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: 'cycle',
      data: {
        'cycleId': cycle.cycleId,
        'symbol': symbol,
        'cycleIndex': cycle.index,
        'cycleReturn': cycle.cycleReturn,
        'durationDays': cycle.durationDays,
        'hadAssignment': cycle.hadAssignment,
        'outcome': cycle.outcome?.toString(),
        'dominantRegime': cycle.dominantRegime?.toString(),
      },
    );

    await repo.addEntry(entry);
  }

  Future<void> recordAssignment(CycleStats cycle, String symbol) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: 'assignment',
      data: {
        'cycleId': cycle.cycleId,
        'symbol': symbol,
        'price': cycle.assignmentPrice,
        'strike': cycle.assignmentStrike,
        'regime': cycle.dominantRegime?.toString(),
      },
    );

    await repo.addEntry(entry);
  }

  Future<void> recordCalledAway(CycleStats cycle, String symbol) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: 'calledAway',
      data: {
        'cycleId': cycle.cycleId,
        'symbol': symbol,
        'price': cycle.calledAwayPrice,
        'strike': cycle.calledAwayStrike,
        'regime': cycle.dominantRegime?.toString(),
      },
    );

    await repo.addEntry(entry);
  }
}
