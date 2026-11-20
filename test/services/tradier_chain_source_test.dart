import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/options/option_chain.dart';
import 'package:riskform/services/options/tradier_chain_source.dart';

class _ServerError extends FirebaseFunctionsException {
  _ServerError(String code, String message)
    : super(code: code, message: message);
}

Map<String, dynamic> _response({List<Object?>? quotes}) => {
  'symbol': 'AAPL',
  'spot': 100.5,
  'asOf': '2026-11-20T15:00:00.000Z',
  'expirationsFetched': ['2026-12-18'],
  'truncated': false,
  'quotes':
      quotes ??
      [
        {
          'right': 'put',
          'strike': 95,
          'expiration': '2026-12-18',
          'bid': 1.2,
          'ask': 1.3,
          'delta': 0.25,
          'ivPercent': 32.0,
          'openInterest': 500,
          'volume': 40,
        },
      ],
};

void main() {
  group('response mapping', () {
    test('maps a response into a chain snapshot', () async {
      final source = TradierChainSource(callable: (_) async => _response());
      final snap = await source.fetch('AAPL');

      expect(snap.underlying, 'AAPL');
      expect(snap.spot, 100.5);
      expect(snap.asOf, DateTime.utc(2026, 11, 20, 15));

      final q = snap.quotes.single;
      expect(q.right, OptionRight.put);
      expect(q.strike, 95);
      expect(q.expiration, DateTime.utc(2026, 12, 18));
      expect(q.bid, 1.2);
      expect(q.ask, 1.3);
      expect(q.delta, 0.25);
      expect(q.impliedVolPercent, 32);
      expect(q.openInterest, 500);
      expect(q.volume, 40);
    });

    test('counts days to expiration from the server date', () async {
      final source = TradierChainSource(callable: (_) async => _response());
      final snap = await source.fetch('AAPL');

      expect(snap.dte(snap.quotes.single), 28);
    });

    test('keeps missing optional values as null', () async {
      final source = TradierChainSource(
        callable: (_) async => _response(
          quotes: [
            {
              'right': 'put',
              'strike': 90,
              'expiration': '2026-12-18',
              'bid': 0.5,
              'ask': null,
              'delta': null,
              'ivPercent': null,
              'openInterest': null,
              'volume': null,
            },
          ],
        ),
      );
      final q = (await source.fetch('AAPL')).quotes.single;

      expect(q.ask, isNull);
      expect(q.delta, isNull);
      expect(q.impliedVolPercent, isNull);
      expect(q.openInterest, isNull);
      expect(q.spreadPercent, isNull);
    });

    test('skips malformed quotes and keeps the rest', () async {
      final source = TradierChainSource(
        callable: (_) async => _response(
          quotes: [
            'garbage',
            {
              'right': 'straddle',
              'strike': 90,
              'expiration': '2026-12-18',
              'bid': 1,
            },
            {
              'right': 'put',
              'strike': 'x',
              'expiration': '2026-12-18',
              'bid': 1,
            },
            {'right': 'put', 'strike': 90, 'expiration': 'soon', 'bid': 1},
            {'right': 'put', 'strike': 90, 'expiration': '2026-12-18'},
            {
              'right': 'call',
              'strike': 105,
              'expiration': '2026-12-18',
              'bid': 0.9,
            },
          ],
        ),
      );
      final quotes = (await source.fetch('AAPL')).quotes;

      expect(quotes.length, 1);
      expect(quotes.single.right, OptionRight.call);
    });

    test('sends the symbol and the expiration window', () async {
      Map<String, dynamic>? sent;
      final source = TradierChainSource(
        callable: (params) async {
          sent = params;
          return _response();
        },
      );
      await source.fetch('AAPL', minDte: 14, maxDte: 45);

      expect(sent, {'symbol': 'AAPL', 'minDte': 14, 'maxDte': 45});
    });

    test('rejects a response with no usable price or date', () async {
      for (final bad in [
        {..._response(), 'spot': null},
        {..._response(), 'spot': 0},
        {..._response(), 'asOf': 'never'},
      ]) {
        final source = TradierChainSource(callable: (_) async => bad);
        await expectLater(
          source.fetch('AAPL'),
          throwsA(isA<LiveChainException>()),
        );
      }
    });
  });

  group('errors', () {
    Future<String> messageFor(Object error) async {
      final source = TradierChainSource(callable: (_) async => throw error);
      try {
        await source.fetch('AAPL');
      } on LiveChainException catch (e) {
        return e.message;
      }
      fail('expected a LiveChainException');
    }

    test('asks the user to sign in', () async {
      expect(
        await messageFor(_ServerError('unauthenticated', 'x')),
        'Sign in to load live data.',
      );
    });

    test('explains when live data is not enabled for the account', () async {
      expect(
        await messageFor(_ServerError('permission-denied', 'internal words')),
        "Live data isn't enabled for your account.",
      );
    });

    test(
      'passes through the server wording for limits and bad symbols',
      () async {
        expect(
          await messageFor(
            _ServerError('resource-exhausted', 'Try again in a minute.'),
          ),
          'Try again in a minute.',
        );
        expect(
          await messageFor(
            _ServerError('invalid-argument', 'Unknown symbol ZZZZ.'),
          ),
          'Unknown symbol ZZZZ.',
        );
      },
    );

    test(
      'hides outages and unexpected failures behind plain messages',
      () async {
        expect(
          await messageFor(_ServerError('unavailable', 'secret detail')),
          'Live data is temporarily unavailable.',
        );
        expect(
          await messageFor(_ServerError('internal', 'secret detail')),
          'Could not load live data.',
        );
        expect(
          await messageFor(StateError('boom')),
          'Could not load live data.',
        );
      },
    );
  });
}
