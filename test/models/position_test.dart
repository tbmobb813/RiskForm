import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/position.dart';

void main() {
  test('Position getters and toJson/fromJson/copyWith', () {
    final now = DateTime.now();
    final exp40 = now.add(const Duration(days: 40));

    final pos = Position(
      type: PositionType.csp,
      symbol: 'ABC',
      strategy: 'ABC',
      quantity: 100,
      expiration: exp40,
      isOpen: true,
      riskFlags: ['f1'],
    );

    // expiration string contains month/day/year
    expect(pos.expirationDateString.contains('${exp40.year}'), isTrue);

    // dte should be positive and near 40 (allow small delta)
    expect(pos.dte, inInclusiveRange(0, 999));

    // stage: for 40 days => mid (<=45)
    expect(pos.stage, PositionStage.mid);

    // lifecycleStage: >30 => Early
    expect(pos.lifecycleStage, 'Early');

    // assignmentProbability for csp with d>20 => 0.10
    expect(pos.assignmentProbability, closeTo(0.10, 0.0001));

    // timeDecayImpact for d>20 => Low
    expect(pos.timeDecayImpact, 'Low');

    final json = pos.toJson();
    final from = Position.fromJson(json);
    expect(from.symbol, pos.symbol);
    expect(from.strategy, pos.strategy);
    expect(from.quantity, pos.quantity);
    expect(from.isOpen, pos.isOpen);

    final copy = pos.copyWith(quantity: 200, isOpen: false);
    expect(copy.quantity, 200);
    expect(copy.isOpen, isFalse);
  });
}
