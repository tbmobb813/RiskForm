import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/utils/parse_date.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

void main() {
  test('parseDate handles null and DateTime', () {
    expect(parseDate(null), isNull);
    final now = DateTime.now();
    expect(parseDate(now), now);
  });

  test('parseDate parses ISO string and integer milliseconds', () {
    final iso = '2020-01-02T03:04:05Z';
    final dt = parseDate(iso);
    expect(dt, isNotNull);
    expect(dt!.toUtc().year, 2020);

    final ms = 1609459200000; // 2021-01-01T00:00:00Z
    final fromMs = parseDate(ms);
    expect(fromMs, DateTime.fromMillisecondsSinceEpoch(ms));
  });

  test('parseDate handles Timestamp and map with seconds/nanos', () {
    final d = DateTime.utc(2021, 6, 1);
    final ts = Timestamp.fromDate(d);
    final parsed = parseDate(ts);
    expect(parsed?.millisecondsSinceEpoch, d.millisecondsSinceEpoch);

    final map = {'_seconds': 1622505600, '_nanoseconds': 500000000};
    final parsedMap = parseDate(map);
    final expectedMs = 1622505600 * 1000 + 500;
    expect(parsedMap?.millisecondsSinceEpoch, expectedMs);
  });

  test('parseDate returns null for unparsable input', () {
    final obj = {'foo': 'bar'};
    expect(parseDate(obj), isNull);
  });
}
