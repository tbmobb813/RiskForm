import '../../models/comparison/comparison_config.dart';
import '../../models/comparison/comparison_result.dart';
import '../../models/backtest/backtest_result.dart';
import 'backtest_engine.dart';
import '../journal/journal_automation_service.dart';

class ComparisonRunner {
  final BacktestEngine engine;
  final JournalAutomationService? journalService;

  ComparisonRunner({required this.engine, this.journalService});

  Future<ComparisonResult> run(ComparisonConfig config) async {
    final results = <BacktestResult>[];

    for (final c in config.configs) {
      final result = engine.run(c);
      // persist journal entries if service provided
      if (journalService != null) {
        for (final cycle in result.cycles) {
          await journalService!.recordCycle(cycle);
          if (cycle.hadAssignment) {
            await journalService!.recordAssignment(cycle);
          }
        }
        await journalService!.recordBacktest(result);
      }
      results.add(result);
    }

    return ComparisonResult(results: results);
  }
}
