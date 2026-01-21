import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/trade_inputs.dart';

class FakeCtrl {
  final String text;
  FakeCtrl(this.text);
}

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

  test('fromControllers parses text values and dates', () {
    final map = {
      'Strike Price': FakeCtrl('42'),
      'Premium Paid': FakeCtrl('1.2'),
      'Shares Owned': FakeCtrl('100'),
      'Expiration Date': FakeCtrl('2022-01-02T00:00:00Z'),
    };

    final inputs = TradeInputs.fromControllers(map);
    expect(inputs.strike, 42);
    expect(inputs.premiumPaid, 1.2);
    expect(inputs.sharesOwned, 100);
    expect(inputs.expiration?.toUtc().year, 2022);
  });

  test('validateForStrategy enforces required fields for csp and cc', () {
    final empty = TradeInputs(underlyingPrice: 100);
    final resCsp = empty.validateForStrategy('csp');
    expect(resCsp.isValid, isFalse);
    expect(resCsp.errors.containsKey('strike'), isTrue);

    final goodCsp = TradeInputs(strike: 50, premiumReceived: 1, underlyingPrice: 100);
    expect(goodCsp.validateForStrategy('csp').isValid, isTrue);

    final emptyCc = TradeInputs(strike: 10, premiumReceived: 1, underlyingPrice: 100);
    final resCc = emptyCc.validateForStrategy('cc');
    expect(resCc.isValid, isFalse);
    expect(resCc.errors.containsKey('costBasis'), isTrue);
    expect(resCc.errors.containsKey('sharesOwned'), isTrue);
  });
}
