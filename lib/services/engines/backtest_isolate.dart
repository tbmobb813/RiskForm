import 'package:riskform/models/backtest/backtest_config.dart';
import 'package:riskform/services/engines/backtest_engine.dart';
import 'package:riskform/services/engines/option_pricing_engine.dart';

/// Entry point for `compute` worker. Accepts a Map (serialized BacktestConfig)
/// and returns a Map (serialized BacktestResult).
Map<String, dynamic> _runBacktestInIsolate(Map<String, dynamic> configMap) {
  final config = BacktestConfig.fromMap(configMap);
  final engine = BacktestEngine(optionPricing: OptionPricingEngine());
  final result = engine.run(config);
  return result.toMap();
}

// Expose a top-level function compatible with `compute`.
Map<String, dynamic> backtestCompute(Map<String, dynamic> input) => _runBacktestInIsolate(input);
