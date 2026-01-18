// ignore_for_file: unused_element

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/trade_plan.dart';

class _FakeDoc {
  final String id;
  final Map<String, dynamic> _data;
  _FakeDoc(this.id, this._data);
  String get docId => id;
  Map<String, dynamic> data() => _data;
}

void main() {
  test('TradePlan.fromDoc parses map correctly', () {
    final data = {
      'strategyId': 'csp',
      'strategyName': 'Cash Secured Put',
      'inputs': {'strike': 50.0},
      'payoff': {
        'maxGain': 100.0,
        'maxLoss': 0.0,
        'breakeven': 50.0,
        'capitalRequired': 5000.0
      },
      'risk': {
        'riskPercentOfAccount': 1.0,
        'assignmentExposure': false,
        'capitalLocked': 10.0,
        'warnings': []
      },
      'notes': 'n',
      'tags': ['t'],
      'createdAt': {'_seconds': 1, '_nanoseconds': 0},
      'updatedAt': {'_seconds': 1, '_nanoseconds': 0},
    };

    final plan = TradePlan.fromMap(data, 'pid');
    expect(plan.id, 'pid');
    expect(plan.strategyId, 'csp');
    expect(plan.strategyName, 'Cash Secured Put');
    expect(plan.tags, ['t']);
  });
}

