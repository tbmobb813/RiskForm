import '../../models/comparison/comparison_config.dart';
import '../../models/comparison/comparison_result.dart';
import '../../models/backtest/backtest_result.dart';
import 'backtest_engine.dart';
import '../journal/journal_automation_service.dart';
import 'package:flutter/foundation.dart';
import 'backtest_isolate.dart';

class ComparisonRunner {
  final BacktestEngine engine;
  final JournalAutomationService? journalService;

  ComparisonRunner({required this.engine, this.journalService});

  Future<ComparisonResult> run(ComparisonConfig config) async {
    final results = <BacktestResult>[];

    for (final c in config.configs) {
      // Run backtest in a background isolate using `compute` for CPU-bound work.
      final mapResult = await compute<Map<String, dynamic>, Map<String, dynamic>>(backtestCompute, c.toMap());
      final result = BacktestResult.fromMap(mapResult);
      // persist journal entries if service provided
      if (journalService != null) {
        final symbol = c.symbol;
        for (final cycle in result.cycles) {
          await journalService!.recordCycle(cycle, symbol);
          if (cycle.hadAssignment) {
            await journalService!.recordAssignment(cycle, symbol);
          }
        }
        await journalService!.recordBacktest(result);
      }
      results.add(result);
    }

    return ComparisonResult(results: results);
  }
}
