import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/trade_plan.dart';
import 'package:flutter_application_2/models/trade_inputs.dart';
import 'package:flutter_application_2/models/payoff_result.dart';
import 'package:flutter_application_2/models/risk_result.dart';

void main() {
  test('TradePlan toJson/fromMap roundtrip preserves timestamps', () {
    final tp = TradePlan(
      id: 't1',
      strategyId: 's1',
      strategyName: 'S',
      inputs: TradeInputs(strike: 10.0),
      payoff: PayoffResult(maxGain: 1, maxLoss: 2, breakeven: 3, capitalRequired: 4),
      risk: RiskResult(riskPercentOfAccount: 1.0, assignmentExposure: false, capitalLocked: 2.0, warnings: []),
      notes: 'n',
      tags: ['a'],
      createdAt: DateTime.utc(2020,1,1),
      updatedAt: DateTime.utc(2020,1,2),
    );

    final json = tp.toJson();
    // should contain Firestore Timestamps
    expect(json['createdAt'] is Timestamp, isTrue);
    expect(json['updatedAt'] is Timestamp, isTrue);

    // roundtrip via fromMap
    final tp2 = TradePlan.fromMap(json, tp.id);
    expect(tp2.createdAt.millisecondsSinceEpoch, tp.createdAt.millisecondsSinceEpoch);
    expect(tp2.updatedAt.millisecondsSinceEpoch, tp.updatedAt.millisecondsSinceEpoch);
  });
}
