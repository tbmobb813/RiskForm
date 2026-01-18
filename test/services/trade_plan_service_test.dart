import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/services/firebase/trade_plan_service.dart';
import 'package:flutter_application_2/models/trade_plan.dart';
import 'package:flutter_application_2/models/trade_inputs.dart';
import 'package:flutter_application_2/models/payoff_result.dart';
import 'package:flutter_application_2/models/risk_result.dart';
import '../fakes/fake_firestore.dart';

void main() {
  group('TradePlanService with FakeFirestore', () {
    test('savePlan sets createdAt and updatedAt for new doc', () async {
      final fake = FakeFirebaseFirestore();
      final service = TradePlanService(fake);

      final plan = TradePlan(
        id: 'p1',
        strategyId: 's1',
        strategyName: 'S',
        inputs: TradeInputs(strike: 10.0),
        payoff: PayoffResult(maxGain: 1, maxLoss: 2, breakeven: 3, capitalRequired: 4),
        risk: RiskResult(riskPercentOfAccount: 1.0, assignmentExposure: false, capitalLocked: 2.0, warnings: []),
        notes: 'n',
        tags: ['a'],
        createdAt: DateTime.utc(2000),
        updatedAt: DateTime.utc(2000),
      );

      await service.savePlan(uid: 'u1', plan: plan);

      final key = 'users/u1/trade_plans/p1';
      expect(fake.store.containsKey(key), isTrue);
      final stored = fake.store[key]!.data;
      expect(stored.containsKey('createdAt'), isTrue);
      expect(stored.containsKey('updatedAt'), isTrue);
      expect(stored['createdAt'] is FieldValue, isTrue);
      expect(stored['updatedAt'] is FieldValue, isTrue);
    });

    test('fetchPlans returns plans sorted by createdAt descending', () async {
      final fake = FakeFirebaseFirestore();
      final service = TradePlanService(fake);

      // create three docs with createdAt timestamps
      final data1 = {
        'strategyId': 'a',
        'strategyName': 'A',
        'inputs': {'strike': 1.0},
        'payoff': {'maxGain': 0.0,'maxLoss':0.0,'breakeven':0.0,'capitalRequired':0.0},
        'risk': {'riskPercentOfAccount':0.0,'assignmentExposure':false,'capitalLocked':0.0,'warnings':<String>[]},
        'notes': '',
        'tags': <String>[],
        'createdAt': Timestamp.fromDate(DateTime.utc(2020,1,1)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2020,1,1)),
      };
      final data2 = Map<String, dynamic>.from(data1)
        ..['createdAt'] = Timestamp.fromDate(DateTime.utc(2021,1,1))
        ..['updatedAt'] = Timestamp.fromDate(DateTime.utc(2021,1,1));
      final data3 = Map<String, dynamic>.from(data1)
        ..['createdAt'] = Timestamp.fromDate(DateTime.utc(2019,1,1))
        ..['updatedAt'] = Timestamp.fromDate(DateTime.utc(2019,1,1));

      fake.store['users/u1/trade_plans/p1'] = InMemoryDoc(data1);
      fake.store['users/u1/trade_plans/p2'] = InMemoryDoc(data2);
      fake.store['users/u1/trade_plans/p3'] = InMemoryDoc(data3);

      final plans = await service.fetchPlans('u1');
      expect(plans.length, 3);
      // first should be p2 (2021), then p1 (2020), then p3 (2019)
      expect(plans[0].id, 'p2');
      expect(plans[1].id, 'p1');
      expect(plans[2].id, 'p3');
    });
  });
}
