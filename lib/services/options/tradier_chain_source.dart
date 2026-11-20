import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'option_chain.dart';

/// Shown to the user when live data cannot be loaded.
class LiveChainException implements Exception {
  final String message;
  const LiveChainException(this.message);

  @override
  String toString() => message;
}

typedef ChainCallable =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> params);

typedef LiveChainFetcher =
    Future<ChainSnapshot> Function(String symbol, {int minDte, int maxDte});

/// Loads live option chains through the `getOptionChain` Cloud Function. The
/// Tradier token stays on the server.
class TradierChainSource {
  final ChainCallable _call;

  TradierChainSource({ChainCallable? callable})
    : _call = callable ?? _callFirebase;

  static Future<Map<String, dynamic>> _callFirebase(
    Map<String, dynamic> params,
  ) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('getOptionChain')
        .call<Object?>(params);
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<ChainSnapshot> fetch(
    String symbol, {
    int minDte = 21,
    int maxDte = 60,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = await _call({
        'symbol': symbol,
        'minDte': minDte,
        'maxDte': maxDte,
      });
    } on FirebaseFunctionsException catch (e) {
      throw LiveChainException(_messageFor(e));
    } on LiveChainException {
      rethrow;
    } catch (_) {
      throw const LiveChainException('Could not load live data.');
    }
    return parse(data, fallbackSymbol: symbol);
  }

  static String _messageFor(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Sign in to load live data.';
      case 'permission-denied':
        return "Live data isn't enabled for your account.";
      case 'resource-exhausted':
      case 'invalid-argument':
        // The server words these for the user, for example an unknown symbol
        // or the hourly limit.
        final message = e.message;
        return (message == null || message.isEmpty)
            ? 'Could not load live data.'
            : message;
      case 'unavailable':
        return 'Live data is temporarily unavailable.';
      default:
        return 'Could not load live data.';
    }
  }

  /// Converts the function's response into a snapshot. Quotes that are
  /// malformed are skipped.
  static ChainSnapshot parse(
    Map<String, dynamic> data, {
    required String fallbackSymbol,
  }) {
    final spot = data['spot'];
    final asOf = DateTime.tryParse('${data['asOf']}');
    if (spot is! num || spot <= 0 || asOf == null) {
      throw const LiveChainException('Live data came back incomplete.');
    }

    final quotes = <OptionQuote>[];
    for (final raw in (data['quotes'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final quote = _quote(Map<String, dynamic>.from(raw));
      if (quote != null) quotes.add(quote);
    }

    return ChainSnapshot(
      underlying: '${data['symbol'] ?? fallbackSymbol}',
      spot: spot.toDouble(),
      asOf: asOf,
      quotes: quotes,
    );
  }

  static OptionQuote? _quote(Map<String, dynamic> q) {
    final right = switch (q['right']) {
      'put' => OptionRight.put,
      'call' => OptionRight.call,
      _ => null,
    };
    final strike = q['strike'];
    final bid = q['bid'];
    final date = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch('${q['expiration']}');
    if (right == null || strike is! num || bid is! num || date == null) {
      return null;
    }

    double? number(String key) =>
        (q[key] is num) ? (q[key] as num).toDouble() : null;

    return OptionQuote(
      right: right,
      strike: strike.toDouble(),
      expiration: DateTime.utc(
        int.parse(date.group(1)!),
        int.parse(date.group(2)!),
        int.parse(date.group(3)!),
      ),
      bid: bid.toDouble(),
      ask: number('ask'),
      delta: number('delta'),
      impliedVolPercent: number('ivPercent'),
      openInterest: number('openInterest')?.round(),
      volume: number('volume')?.round(),
    );
  }
}

final liveChainFetcherProvider = Provider<LiveChainFetcher>(
  (ref) => TradierChainSource().fetch,
);
