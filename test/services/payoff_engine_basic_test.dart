import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/payoff_engine.dart';
import 'package:riskform/models/trade_inputs.dart';

void main() {
  final engine = PayoffEngine();

  test('compute cash-secured put basic numbers', () async {
    final inputs = TradeInputs(strike: 50, premiumReceived: 2);
    final result = await engine.compute(strategyId: 'csp', inputs: inputs);

    // capitalRequired = K * 100
    expect(result.capitalRequired, 50 * PayoffEngine.contractSize);
    // maxGain = premium * 100
    expect(result.maxGain, 2 * PayoffEngine.contractSize);
    // breakeven = K - premium
    expect(result.breakeven, 48);
  });

  test('long call payoffAtPrice behavior', () {
    final inputs = TradeInputs(strike: 100, premiumPaid: 3);
    // at S = 110, payoff per contract = (-premium + max(0, S-K)) * 100 = (-3 + 10)*100 = 700
    final payoff = engine.payoffAtPrice(strategyId: 'long_call', inputs: inputs, underlyingPrice: 110);
    expect(payoff, closeTo(700, 0.001));
  });
}
