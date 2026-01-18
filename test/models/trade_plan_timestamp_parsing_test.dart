import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/trade_plan.dart';

void main() {
  group('TradePlan.fromMap timestamp parsing', () {
    final base = {
      'strategyId': 's1',
      'strategyName': 'Test Strategy',
      'inputs': {'strike': 100.0},
      'payoff': {
        'maxGain': 0.0,
        'maxLoss': 0.0,
        'breakeven': 0.0,
        'capitalRequired': 0.0
      },
      'risk': {
        'riskPercentOfAccount': 0.0,
        'assignmentExposure': false,
        'capitalLocked': 0.0,
        'warnings': <String>[]
      },
      'notes': 'x',
      'tags': <String>['a']
    };

    test('parses Firestore Timestamp', () {
      final dt = DateTime.utc(2021, 1, 1, 12, 34, 56);
      final data = Map<String, dynamic>.from(base)
        ..['createdAt'] = Timestamp.fromDate(dt)
        ..['updatedAt'] = Timestamp.fromDate(dt);

      final p = TradePlan.fromMap(data, 'id1');
      expect(p.createdAt.millisecondsSinceEpoch, dt.millisecondsSinceEpoch);
      expect(p.updatedAt.millisecondsSinceEpoch, dt.millisecondsSinceEpoch);
    });

    test('parses ISO string', () {
      final dt = DateTime.utc(2022, 2, 2, 2, 2, 2);
      final data = Map<String, dynamic>.from(base)
        ..['createdAt'] = dt.toIso8601String()
        ..['updatedAt'] = dt.toIso8601String();

      final p = TradePlan.fromMap(data, 'id2');
      expect(p.createdAt.toIso8601String(), dt.toIso8601String());
      expect(p.updatedAt.toIso8601String(), dt.toIso8601String());
    });

    test('parses map with _seconds/_nanoseconds', () {
      // choose a fixed epoch seconds
      final seconds = 1600000000; // ~2020-09-13
      final ns = 0;
      final expected = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

      final data = Map<String, dynamic>.from(base)
        ..['createdAt'] = {'_seconds': seconds, '_nanoseconds': ns}
        ..['updatedAt'] = {'_seconds': seconds, '_nanoseconds': ns};

      final p = TradePlan.fromMap(data, 'id3');
      expect(p.createdAt.millisecondsSinceEpoch, expected.millisecondsSinceEpoch);
      expect(p.updatedAt.millisecondsSinceEpoch, expected.millisecondsSinceEpoch);
    });

    test('null timestamps become epoch', () {
      final data = Map<String, dynamic>.from(base)
        ..['createdAt'] = null
        ..['updatedAt'] = null;

      final p = TradePlan.fromMap(data, 'id4');
      expect(p.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(p.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
