import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/engines/comparison_runner.dart';
import 'backtest_engine_provider.dart';
import 'journal_providers.dart';


final comparisonRunnerProvider = Provider<ComparisonRunner>((ref) {
  final engine = ref.read(backtestEngineProvider);
  final journal = ref.read(journalAutomationProvider);
  return ComparisonRunner(engine: engine, journalService: journal);
});
