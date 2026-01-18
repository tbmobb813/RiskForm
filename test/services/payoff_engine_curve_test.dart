import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/engines/payoff_engine.dart';
import 'package:flutter_application_2/models/trade_inputs.dart';

void main() {
  group('PayoffEngine payoffAtPrice', () {
    final engine = PayoffEngine();

    test('csp payoff at prices', () {
      final inputs = TradeInputs(strike: 50.0, premiumReceived: 2.0);
      // below strike -> payoff = premium - (K - S)
      final below = engine.payoffAtPrice(strategyId: 'csp', inputs: inputs, underlyingPrice: 45.0);
      expect(below, (2.0 - (50.0 - 45.0)) * PayoffEngine.contractSize);

      // at strike -> payoff == premium
      final at = engine.payoffAtPrice(strategyId: 'csp', inputs: inputs, underlyingPrice: 50.0);
      expect(at, 2.0 * PayoffEngine.contractSize);

      // above strike -> payoff == premium
      final above = engine.payoffAtPrice(strategyId: 'csp', inputs: inputs, underlyingPrice: 60.0);
      expect(above, 2.0 * PayoffEngine.contractSize);
    });

    test('long_call payoff at prices', () {
      final inputs = TradeInputs(strike: 100.0, premiumPaid: 1.5);
      final below = engine.payoffAtPrice(strategyId: 'long_call', inputs: inputs, underlyingPrice: 90.0);
      expect(below, -1.5 * PayoffEngine.contractSize);

      final at = engine.payoffAtPrice(strategyId: 'long_call', inputs: inputs, underlyingPrice: 100.0);
      expect(at, -1.5 * PayoffEngine.contractSize);

      final above = engine.payoffAtPrice(strategyId: 'long_call', inputs: inputs, underlyingPrice: 110.0);
      expect(above, (-1.5 + (110.0 - 100.0)) * PayoffEngine.contractSize);
    });
  });

  group('PayoffEngine generatePayoffCurve', () {
    final engine = PayoffEngine();

    test('curve length and monotonic price axis', () {
      final inputs = TradeInputs(strike: 100.0, premiumPaid: 1.0);
      final curve = engine.generatePayoffCurve(
        strategyId: 'long_call',
        inputs: inputs,
        minPrice: 80.0,
        maxPrice: 120.0,
        points: 41,
      );

      expect(curve.length, 41);
      // price axis should be increasing
      for (int i = 1; i < curve.length; i++) {
        expect(curve[i].dx, greaterThan(curve[i - 1].dx));
      }

      // check endpoints roughly match payoffAtPrice
      final startPay = engine.payoffAtPrice(strategyId: 'long_call', inputs: inputs, underlyingPrice: 80.0);
      final endPay = engine.payoffAtPrice(strategyId: 'long_call', inputs: inputs, underlyingPrice: 120.0);

      expect(curve.first.dy, closeTo(startPay, 1e-6));
      expect(curve.last.dy, closeTo(endPay, 1e-6));
    });
  });
}
