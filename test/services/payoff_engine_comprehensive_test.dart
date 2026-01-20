import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/payoff_engine.dart';
import 'package:riskform/models/trade_inputs.dart';

void main() {
  final engine = PayoffEngine();

  group('PayoffEngine comprehensive', () {
    test('csp calculations', () async {
      final inputs = TradeInputs(strike: 50.0, premiumReceived: 2.0);
      final p = await engine.compute(strategyId: 'csp', inputs: inputs);
      expect(p.capitalRequired, 50.0 * PayoffEngine.contractSize);
      expect(p.maxGain, 2.0 * PayoffEngine.contractSize);
      expect(p.breakeven, 48.0);
    });

    test('covered call calculations', () async {
      final inputs = TradeInputs(strike: 60.0, premiumReceived: 1.5, costBasis: 55.0);
      final p = await engine.compute(strategyId: 'cc', inputs: inputs);
      expect(p.capitalRequired, 55.0 * PayoffEngine.contractSize);
      expect(p.maxGain, ((60.0 - 55.0) + 1.5) * PayoffEngine.contractSize);
      expect(p.breakeven, 55.0 - 1.5);
    });

    test('debit spread calculations', () async {
      final inputs = TradeInputs(longStrike: 50.0, shortStrike: 55.0, netDebit: 1.0);
      final p = await engine.compute(strategyId: 'debit_spread', inputs: inputs);
      expect(p.maxLoss, 1.0 * PayoffEngine.contractSize);
      expect(p.maxGain, ((55.0 - 50.0) - 1.0) * PayoffEngine.contractSize);
    });

    test('collar calculations', () async {
      final inputs = TradeInputs(strike: 65.0, longStrike: 45.0, premiumReceived: 2.0, premiumPaid: 1.0, costBasis: 50.0);
      final p = await engine.compute(strategyId: 'collar', inputs: inputs);
      final netPremium = 2.0 - 1.0;
      expect(p.capitalRequired, (50.0 + 1.0 - 2.0) * PayoffEngine.contractSize);
      expect(p.breakeven, 50.0 + netPremium);
    });

    test('placeholder fallback', () async {
      final inputs = TradeInputs(underlyingPrice: 123.0);
      final p = await engine.compute(strategyId: 'unknown', inputs: inputs);
      expect(p.breakeven, 123.0);
    });
  });
}
