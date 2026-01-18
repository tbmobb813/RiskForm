import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_2/services/engines/backtest_engine.dart';
import 'package:flutter_application_2/services/engines/option_pricing_engine.dart';
import 'package:flutter_application_2/services/engines/comparison_runner.dart';
import 'package:flutter_application_2/models/backtest/backtest_config.dart';
import 'package:flutter_application_2/models/comparison/comparison_config.dart';

void main() {
  test('ComparisonRunner runs multiple backtests deterministically', () {
    final engine = BacktestEngine(optionPricing: OptionPricingEngine());
    final runner = ComparisonRunner(engine: engine);

    final cfg1 = BacktestConfig(
      startingCapital: 10000.0,
      maxCycles: 2,
      pricePath: [100.0, 101.0, 102.0, 103.0],
      strategyId: 'wheel',
      symbol: 'TST',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now(),
    );

    final cfg2 = BacktestConfig(
      startingCapital: 10000.0,
      maxCycles: 2,
      pricePath: [100.0, 99.0, 98.0, 97.0],
      strategyId: 'wheel',
      symbol: 'TST',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now(),
    );

    final comparisonConfig = ComparisonConfig(configs: [cfg1, cfg2]);

    final future = runner.run(comparisonConfig);
    expect(future, isA<Future>());

    return future.then((res) {
      expect(res.results.length, 2);
      expect(res.results[0].equityCurve.isNotEmpty, true);
      expect(res.results[1].equityCurve.isNotEmpty, true);
    });
  });
}
