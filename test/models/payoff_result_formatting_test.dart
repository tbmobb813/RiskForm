import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/payoff_result.dart';

void main() {
  test('PayoffResult formatting strings', () {
    final p = PayoffResult(maxGain: 1234.5, maxLoss: 10.0, breakeven: 100.0, capitalRequired: 500.0);
    expect(p.maxGainString.startsWith('\$1234.50'), isTrue);
    expect(p.maxLossString.startsWith('\$10.00'), isTrue);
    expect(p.breakevenString.startsWith('\$100.00'), isTrue);
  });
}
