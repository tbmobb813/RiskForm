import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/risk_engine.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/models/trade_inputs.dart';
import 'package:riskform/models/payoff_result.dart';

void main() {
  test('RiskEngine computes high risk and warnings', () async {
    final account = AccountContext(accountSize: 10000.0, buyingPower: 8000.0);
    final engine = RiskEngine(account);

    final inputs = TradeInputs(strike: 50.0, premiumReceived: 2.0);
    final payoff = PayoffResult(
      maxGain: 200.0,
      maxLoss: 4800.0,
      breakeven: 48.0,
      capitalRequired: 5000.0,
    );

    final result = await engine.compute(strategyId: 'csp', inputs: inputs, payoff: payoff);

    expect(result.riskPercentOfAccount, closeTo(50.0, 0.001));
    expect(result.warnings, contains('This trade locks more than 10% of your account.'));
    expect(result.assignmentExposure, isTrue);
  });
}
