import 'package:test/test.dart';
import 'package:riskform_cloud_worker/backtest_engine.dart';

void main() {
  test('CloudBacktestEngine.run throws on zero or negative prices', () {
    final engine = CloudBacktestEngine();

    // PricePath with zero as the first price should trigger pricing on step 0
    final badConfig1 = {
      'startingCapital': 10000,
      'pricePath': [0.0, 100.0, 105.0],
    };

    final badConfig2 = {
      'startingCapital': 10000,
      'pricePath': [-5.0, 100.0, 110.0],
    };

    expect(() => engine.run(badConfig1), throwsA(isA<StateError>()));
    expect(() => engine.run(badConfig2), throwsA(isA<StateError>()));
  });
}
