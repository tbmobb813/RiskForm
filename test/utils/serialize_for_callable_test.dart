import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/utils/serialize_for_callable.dart' as ser;

void main() {
  test('serialize DateTime and Timestamp to ISO strings', () {
    final now = DateTime.parse('2020-01-02T03:04:05Z');
    final ts = Timestamp.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);

    final input = {
      'time': now,
      'ts': ts,
      'nested': {
        'list': [now, ts, 'keep']
      },
      'value': 42,
    };

    final out = ser.serializeForCallable(input) as Map<String, dynamic>;

    expect(out['time'], isA<String>());
    expect(out['time'], equals(now.toIso8601String()));
    expect(out['ts'], isA<String>());
    expect(out['ts'], equals(now.toIso8601String()));
    expect(out['nested'], isA<Map>());
    final nested = out['nested'] as Map<String, dynamic>;
    expect(nested['list'][0], equals(now.toIso8601String()));
    expect(nested['list'][1], equals(now.toIso8601String()));
    expect(nested['list'][2], equals('keep'));
    expect(out['value'], equals(42));
  });
}
