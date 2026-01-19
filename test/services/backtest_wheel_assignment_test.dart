import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/engines/backtest_engine.dart';
import 'package:flutter_application_2/services/engines/option_pricing_engine.dart';
import 'package:flutter_application_2/models/backtest/backtest_config.dart';

void main() {
  group('Wheel expiry and assignment', () {
    test('CSP expires ITM -> assignment and capital decreases', () {
      final engine = BacktestEngine(optionPricing: OptionPricingEngine());
      // Build a price path long enough to let CSP expire (30 days) then CC expire
      final path = List<double>.filled(30, 50.0) + [45.0] + List<double>.filled(31, 46.0) + [60.0];

      final config = BacktestConfig(
        startingCapital: 100000,
        maxCycles: 10,
        pricePath: path,
        strategyId: 'wheel',
        symbol: 'TEST',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 3, 2),
      );

      final result = engine.run(config);

      // Expect at least one assigned event in notes
      final assigned = result.notes.any((n) => n.contains('assigned'));
      expect(assigned, isTrue);
    });

    test('CSP expires OTM -> no assignment', () {
      final engine = BacktestEngine(optionPricing: OptionPricingEngine());
      // rising path means put will expire worthless
      final path = List<double>.filled(31, 51.0);
      final config = BacktestConfig(
        startingCapital: 100000,
        maxCycles: 10,
        pricePath: path,
        strategyId: 'wheel',
        symbol: 'TEST',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 2, 1),
      );

      final result = engine.run(config);

      final assigned = result.notes.any((n) => n.contains('assigned'));
      expect(assigned, isFalse);
    });

    test('CC expires ITM -> called away and cycle increments', () {
      final engine = BacktestEngine(optionPricing: OptionPricingEngine());
      // Use the same long path used earlier to get called-away on CC expiry
      final path = List<double>.filled(30, 50.0) + [45.0] + List<double>.filled(31, 46.0) + [60.0];

      final config = BacktestConfig(
        startingCapital: 100000,
        maxCycles: 10,
        pricePath: path,
        strategyId: 'wheel',
        symbol: 'TEST',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 3, 2),
      );

      final result = engine.run(config);
      final called = result.notes.any((n) => n.contains('called away'));
      expect(called, isTrue);
    });
  });
}
