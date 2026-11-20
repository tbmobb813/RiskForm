import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/options/chain_parser.dart';
import 'package:riskform/services/options/option_chain.dart';

void main() {
  const parser = ChainParser();
  final asOf = DateTime(2026, 11, 20, 15, 30);

  group('columns and values', () {
    test('parses a comma-separated chain with common column names', () {
      final r = parser.parse(
        'Type,Strike,Expiration,Bid,Ask,Delta,IV,Open Interest,Volume\n'
        'put,95,2026-12-18,1.20,1.30,-0.25,32%,500,40\n'
        'call,105,12/18/2026,0.90,1.00,0.22,0.30,300,25\n',
        asOf: asOf,
      );

      expect(r.errors, isEmpty);
      expect(r.quotes.length, 2);

      final put = r.quotes[0];
      expect(put.right, OptionRight.put);
      expect(put.strike, 95);
      expect(put.expiration, DateTime.utc(2026, 12, 18));
      expect(put.bid, 1.20);
      expect(put.ask, 1.30);
      expect(put.delta, 0.25);
      expect(put.impliedVolPercent, 32);
      expect(put.openInterest, 500);
      expect(put.volume, 40);

      final call = r.quotes[1];
      expect(call.right, OptionRight.call);
      expect(call.expiration, DateTime.utc(2026, 12, 18));
      expect(call.impliedVolPercent, closeTo(30, 1e-9));
    });

    test('parses tab-separated text and dollar-formatted numbers', () {
      final r = parser.parse(
        'Strike\tBid\tAsk\tDTE\n\$90.00\t\$0.50\t\$0.55\t30\n',
        asOf: asOf,
      );

      expect(r.errors, isEmpty);
      final q = r.quotes.single;
      expect(q.right, OptionRight.put);
      expect(q.strike, 90);
      expect(q.bid, 0.5);
      expect(q.expiration, DateTime.utc(2026, 12, 20));
    });

    test('uses the default right when there is no type column', () {
      final r = parser.parse(
        'strike,bid,dte\n50,1,30\n',
        asOf: asOf,
        defaultRight: OptionRight.call,
      );
      expect(r.quotes.single.right, OptionRight.call);
    });

    test('leaves optional values null when blank', () {
      final r = parser.parse(
        'strike,bid,ask,dte,delta,oi\n50,1,,30,,\n',
        asOf: asOf,
      );

      final q = r.quotes.single;
      expect(q.ask, isNull);
      expect(q.delta, isNull);
      expect(q.openInterest, isNull);
      expect(q.spreadPercent, isNull);
    });

    test('computes mid and spread percent', () {
      final r = parser.parse(
        'strike,bid,ask,dte\n50,1.00,1.20,30\n',
        asOf: asOf,
      );

      final q = r.quotes.single;
      expect(q.mid, closeTo(1.10, 1e-9));
      expect(q.spreadPercent, closeTo(0.2 / 1.1 * 100, 1e-9));
    });
  });

  group('snapshot', () {
    test('counts calendar days from the as-of date', () {
      final snap = ChainSnapshot(
        underlying: 'AAPL',
        spot: 100,
        asOf: asOf,
        quotes: const [],
      );
      final q = OptionQuote(
        right: OptionRight.put,
        strike: 95,
        expiration: DateTime.utc(2026, 12, 20),
        bid: 1,
      );
      expect(snap.dte(q), 30);
    });
  });

  group('bad input', () {
    test('reports a missing header', () {
      final r = parser.parse('foo,bar\n1,2\n', asOf: asOf);
      expect(r.quotes, isEmpty);
      expect(r.errors.single, contains('strike'));
      expect(r.errors.single, contains('bid'));
      expect(r.errors.single, contains('expiration or DTE'));
    });

    test('reports empty text', () {
      expect(parser.parse('  \n ', asOf: asOf).errors, isNotEmpty);
    });

    test('skips bad rows and keeps the good ones', () {
      final r = parser.parse(
        'strike,bid,ask,dte,type\n'
        'abc,1,1.1,30,put\n'
        '50,x,1.1,30,put\n'
        '50,1,1.1,never,put\n'
        '50,1.2,1.0,30,put\n'
        '50,1,1.1,30,straddle\n'
        '55,1,1.1,30,put\n',
        asOf: asOf,
      );

      expect(r.quotes.map((q) => q.strike), [55]);
      expect(r.errors, [
        'Line 2: bad strike.',
        'Line 3: bad bid.',
        'Line 4: bad expiration or DTE.',
        'Line 5: ask is below bid.',
        'Line 6: type must be put or call.',
      ]);
    });
  });
}
