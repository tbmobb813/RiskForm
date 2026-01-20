import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/comparison_runner.dart';
import 'package:riskform/services/engines/backtest_engine.dart';
import 'package:riskform/services/engines/option_pricing_engine.dart';
import 'package:riskform/models/comparison/comparison_config.dart';

void main() {
  test('ComparisonRunner returns empty results for empty config', () async {
    final runner = ComparisonRunner(engine: BacktestEngine(optionPricing: OptionPricingEngine()));
    final config = ComparisonConfig(configs: []);
    final result = await runner.run(config);
    expect(result.results, isEmpty);
  });
}
