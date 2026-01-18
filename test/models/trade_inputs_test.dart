import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/trade_inputs.dart';

void main() {
  test('TradeInputs toJson and fromJson roundtrip', () {
    final inputs = TradeInputs(
      strike: 50.0,
      premiumPaid: 1.5,
      premiumReceived: 2.0,
      netCredit: 2.0,
      underlyingPrice: 55.0,
      sharesOwned: 100,
    );

    final json = inputs.toJson();
    final restored = TradeInputs.fromJson(json);

    expect(restored.strike, inputs.strike);
    expect(restored.premiumPaid, inputs.premiumPaid);
    expect(restored.premiumReceived, inputs.premiumReceived);
    expect(restored.netCredit, inputs.netCredit);
    expect(restored.underlyingPrice, inputs.underlyingPrice);
    expect(restored.sharesOwned, inputs.sharesOwned);
  });
}
