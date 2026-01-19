import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/engines/comparison_runner.dart';
import 'package:flutter_application_2/services/engines/backtest_engine.dart';
import 'package:flutter_application_2/services/engines/option_pricing_engine.dart';
import 'package:flutter_application_2/models/comparison/comparison_config.dart';

void main() {
  test('ComparisonRunner returns empty results for empty config', () async {
    final runner = ComparisonRunner(engine: BacktestEngine(optionPricing: OptionPricingEngine()));
    final config = ComparisonConfig(configs: []);
    final result = await runner.run(config);
    expect(result.results, isEmpty);
  });
}
