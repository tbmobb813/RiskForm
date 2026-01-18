import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/engines/payoff_engine.dart';
import 'package:flutter_application_2/models/trade_inputs.dart';
// removed unused import

void main() {
  final engine = PayoffEngine();

  test('Cash-secured put payoff calculation', () {
    final inputs = TradeInputs(strike: 50.0, premiumReceived: 2.0);
    final payoff = engine.compute(strategyId: 'csp', inputs: inputs);

    expect(payoff, isA<Future>());
    payoff.then((p) {
      expect(p.capitalRequired, 50.0 * PayoffEngine.contractSize);
      expect(p.maxGain, 2.0 * PayoffEngine.contractSize);
      expect(p.maxLoss, (50.0 - 2.0) * PayoffEngine.contractSize);
      expect(p.breakeven, 48.0);
    });
  });

  test('Credit spread payoff calculation', () async {
    final inputs = TradeInputs(shortStrike: 55.0, longStrike: 50.0, netCredit: 1.0);
    final p = await engine.compute(strategyId: 'credit_spread', inputs: inputs);

    expect(p.maxGain, 1.0 * PayoffEngine.contractSize);
    expect(p.maxLoss, (5.0 - 1.0) * PayoffEngine.contractSize);
    expect(p.breakeven, 55.0 - 1.0);
  });

  test('Long call returns infinite maxGain and correct maxLoss', () async {
    final inputs = TradeInputs(strike: 100.0, premiumPaid: 3.0);
    final p = await engine.compute(strategyId: 'long_call', inputs: inputs);

    expect(p.maxGain.isInfinite, isTrue);
    expect(p.maxLoss, 3.0 * PayoffEngine.contractSize);
    expect(p.breakeven, 103.0);
  });
}
