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

  test('Black-Scholes wrappers validate S and K and handle sigma/T', () {
    final engine = CloudBacktestEngine();

    // Non-positive S or K should throw
    expect(() => engine.priceCall(0.0, 100.0, 0.25, 0.1), throwsA(isA<StateError>()));
    expect(() => engine.pricePut(-1.0, 100.0, 0.25, 0.1), throwsA(isA<StateError>()));

    // Zero sigma or zero T should return intrinsic value (no NaN)
    final callIntrinsic = engine.priceCall(120.0, 100.0, 0.0, 0.1);
    expect(callIntrinsic, equals(20.0));

    final putIntrinsic = engine.pricePut(80.0, 100.0, 0.0, 0.0);
    expect(putIntrinsic, equals(20.0));
  });
}
