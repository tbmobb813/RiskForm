import '../../models/comparison/comparison_config.dart';
import '../../models/comparison/comparison_result.dart';
import '../../models/backtest/backtest_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backtest_engine.dart';

class ComparisonRunner {
  final BacktestEngine engine;

  ComparisonRunner({required this.engine});

  Future<ComparisonResult> run(ComparisonConfig config) async {
    final results = <BacktestResult>[];

    for (final c in config.configs) {
      final result = engine.run(c);
      results.add(result);
    }

    return ComparisonResult(results: results);
  }
}
