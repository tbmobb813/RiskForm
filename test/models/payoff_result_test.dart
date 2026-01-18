import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/payoff_result.dart';

void main() {
  test('PayoffResult string getters format currency', () {
    final p = PayoffResult(maxGain: 1234.5, maxLoss: 10.0, breakeven: 50.0, capitalRequired: 500.0);

    expect(p.maxGainString, r"$1234.50");
    expect(p.maxLossString, r"$10.00");
    expect(p.breakevenString, r"$50.00");
    expect(p.capitalRequiredString, r"$500.00");
  });
}
