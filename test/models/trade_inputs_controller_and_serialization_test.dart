import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/trade_inputs.dart';

class _F {
  String text;
  _F(this.text);
}

void main() {
  group('TradeInputs fromControllers and serialization', () {
    test('fromControllers parses numbers and dates', () {
      final controllers = {
        'Strike Price': _F('42.5'),
        'Premium Paid': _F('1.5'),
        'Shares Owned': _F('100'),
        'Expiration Date': _F('2023-12-31')
      };

      final t = TradeInputs.fromControllers(controllers);
      expect(t.strike, 42.5);
      expect(t.premiumPaid, 1.5);
      expect(t.sharesOwned, 100);
      expect(t.expiration?.year, 2023);
    });

    test('toJson and fromJson roundtrip', () {
      final orig = TradeInputs(
        strike: 50.0,
        premiumPaid: 2.0,
        netCredit: 1.0,
        sharesOwned: 100,
      );

      final json = orig.toJson();
      final parsed = TradeInputs.fromJson(json);
      expect(parsed.strike, orig.strike);
      expect(parsed.premiumPaid, orig.premiumPaid);
      expect(parsed.sharesOwned, orig.sharesOwned);
    });
  });
}
