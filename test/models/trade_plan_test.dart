import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/trade_plan.dart';
import 'package:riskform/models/trade_inputs.dart';
import 'package:riskform/models/payoff_result.dart';
import 'package:riskform/models/risk_result.dart';

void main() {
  test('TradePlan toJson contains expected keys and values', () {
    final inputs = TradeInputs(strike: 50.0);
    final payoff = PayoffResult(maxGain: 100.0, maxLoss: 0.0, breakeven: 50.0, capitalRequired: 5000.0);
    final risk = RiskResult(riskPercentOfAccount: 5.0, assignmentExposure: false, capitalLocked: 500.0, warnings: []);

    final plan = TradePlan(
      id: '1',
      strategyId: 'csp',
      strategyName: 'Cash Secured Put',
      inputs: inputs,
      payoff: payoff,
      risk: risk,
      notes: 'note',
      tags: ['income'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    final json = plan.toJson();
    expect(json['strategyId'], 'csp');
    expect(json['strategyName'], 'Cash Secured Put');
    expect(json['inputs'], isA<Map<String, dynamic>>());
    expect(json['payoff']['capitalRequired'], 5000.0);
    expect(json['risk']['riskPercentOfAccount'], 5.0);
  });
}
