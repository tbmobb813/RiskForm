import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/cloud/cloud_backtest_job.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

Map<String, dynamic> _baseMap(dynamic submittedAt, {dynamic startedAt, dynamic completedAt}) {
  return {
    'jobId': 'job-123',
    'userId': 'user-abc',
    'submittedAt': submittedAt,
    'startedAt': startedAt,
    'completedAt': completedAt,
    'status': 'queued',
    'configUsed': {
      'startingCapital': 1000.0,
      'maxCycles': 1,
      'pricePath': [1.0, 2.0],
      'strategyId': 's1',
      'symbol': 'SYM',
      'startDate': '2020-01-01T00:00:00Z',
      'endDate': '2020-01-02T00:00:00Z',
    },
    'engineVersion': '1.0.0',
  };
}

void main() {
  test('parses Firestore Timestamp', () {
    final dt = DateTime.utc(2025, 1, 1);
    final ts = Timestamp.fromDate(dt);
    final job = CloudBacktestJob.fromMap(_baseMap(ts));
    expect(job.submittedAt.toUtc(), equals(dt));
  });

  test('parses ISO8601 string', () {
    final s = '2024-12-31T23:59:59Z';
    final expected = DateTime.parse(s).toUtc();
    final job = CloudBacktestJob.fromMap(_baseMap(s));
    expect(job.submittedAt.toUtc(), equals(expected));
  });

  test('parses milliseconds since epoch (int)', () {
    final dt = DateTime.utc(2023, 6, 30, 12, 0, 0);
    final ms = dt.millisecondsSinceEpoch;
    final job = CloudBacktestJob.fromMap(_baseMap(ms));
    expect(job.submittedAt.toUtc(), equals(dt));
  });

  test('accepts DateTime directly', () {
    final dt = DateTime.now().toUtc();
    final job = CloudBacktestJob.fromMap(_baseMap(dt));
    // Compare using toIso8601String to avoid millisecond rounding issues
    expect(job.submittedAt.toIso8601String(), equals(dt.toIso8601String()));
  });

  test('returns null for unparsable optional dates', () {
    final job = CloudBacktestJob.fromMap(_baseMap('2023-01-01T00:00:00Z', startedAt: 'not-a-date'));
    expect(job.startedAt, isNull);
  });
}
