import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/utils/firestore_helpers.dart' as fh;

void main() {
  test('toFirestoreMap converts DateTime to Timestamp and preserves numbers', () {
    final dt = DateTime.utc(2021, 5, 6, 7, 8, 9);
    final input = {
      'a': dt,
      'b': 42,
      'nested': {'x': dt, 'y': null},
      'list': [dt, 1, null]
    };

    final out = fh.toFirestoreMap(input);
    expect(out['a'], isA<Timestamp>());
    expect((out['a'] as Timestamp).toDate().toUtc().millisecondsSinceEpoch, equals(dt.millisecondsSinceEpoch));
    expect(out['b'], equals(42));

    final nested = out['nested'] as Map<String, dynamic>;
    expect(nested['x'], isA<Timestamp>());
    expect((nested['x'] as Timestamp).toDate().toUtc().millisecondsSinceEpoch, equals(dt.millisecondsSinceEpoch));
    expect(nested.containsKey('y'), isTrue);

    final list = out['list'] as List;
    expect(list[0], isA<Timestamp>());
    expect((list[0] as Timestamp).toDate().toUtc().millisecondsSinceEpoch, equals(dt.millisecondsSinceEpoch));
    expect(list[1], equals(1));
    expect(list[2], isNull);
  });

  test('stripNulls removes nulls shallowly', () {
    final input = {'a': 1, 'b': null, 'c': 'ok'};
    final out = fh.stripNulls(input);
    expect(out.containsKey('a'), isTrue);
    expect(out.containsKey('b'), isFalse);
    expect(out.containsKey('c'), isTrue);
  });
}
