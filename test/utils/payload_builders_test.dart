import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/payload_builders.dart' as pb;

void main() {
  test('buildScoreTradePayload serializes DateTime fields', () {
    final dt = DateTime.utc(2022, 1, 2, 3, 4, 5);
    final planned = {'plannedEntryTime': dt, 'strike': 10};
    final exec = {'executedAt': dt, 'entryPrice': 5.5};

    final payload = pb.buildScoreTradePayload(journalId: 'j1', plannedParams: planned, executedParams: exec);
    expect(payload['journalId'], equals('j1'));
    expect(payload['plannedParams']['plannedEntryTime'], equals(dt.toIso8601String()));
    expect(payload['executedParams']['executedAt'], equals(dt.toIso8601String()));
    expect(payload['plannedParams']['strike'], equals(10));
  });
}
