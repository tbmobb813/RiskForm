import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/engines/risk_engine.dart';
import 'package:flutter_application_2/models/account_context.dart';
import 'package:flutter_application_2/models/trade_inputs.dart';
import 'package:flutter_application_2/models/payoff_result.dart';

void main() {
  group('RiskEngine guardrails and exposure', () {
    test('warns when riskPercent > 5 and >10 and assignment exposure and buying power exceeded', () async {
      final account = AccountContext(accountSize: 1000.0, buyingPower: 100.0);
      final engine = RiskEngine(account);

      // Make capitalLocked large to trigger both >5% and >10% and exceed buying power
      final payoff = PayoffResult(maxGain: 0, maxLoss: 500.0, breakeven: 0, capitalRequired: 500.0);
      final inputs = TradeInputs();

      final res = await engine.compute(strategyId: 'csp', inputs: inputs, payoff: payoff);
      expect(res.warnings.length >= 3, isTrue);
      expect(res.assignmentExposure, isTrue);
      expect(res.riskPercentOfAccount > 10, isTrue);
    });

    test('no warnings for tiny trades', () async {
      final account = AccountContext(accountSize: 100000.0, buyingPower: 100000.0);
      final engine = RiskEngine(account);

      final payoff = PayoffResult(maxGain: 10, maxLoss: 50.0, breakeven: 0, capitalRequired: 50.0);
      final inputs = TradeInputs();

      final res = await engine.compute(strategyId: 'long_call', inputs: inputs, payoff: payoff);
      // long_call has no assignment exposure
      expect(res.warnings.isEmpty, isTrue);
      expect(res.assignmentExposure, isFalse);
    });
  });
}
