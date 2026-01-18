import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/engines/comparison_runner.dart';
import 'backtest_engine_provider.dart';

final comparisonRunnerProvider = Provider<ComparisonRunner>((ref) {
  final engine = ref.read(backtestEngineProvider);
  return ComparisonRunner(engine: engine);
});
