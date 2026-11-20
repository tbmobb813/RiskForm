/// Provider-neutral option chain data. Any data source (a pasted export, a
/// broker API) should be converted into a [ChainSnapshot]; the screener only
/// depends on these types.
library;

enum OptionRight { put, call }

class OptionQuote {
  final OptionRight right;
  final double strike;
  final DateTime expiration;
  final double bid;

  /// Null when the source did not provide an ask.
  final double? ask;

  /// Absolute delta (0 to 1), when provided.
  final double? delta;

  /// Implied volatility in percent (for example 32 for 32%), when provided.
  final double? impliedVolPercent;

  final int? openInterest;
  final int? volume;

  const OptionQuote({
    required this.right,
    required this.strike,
    required this.expiration,
    required this.bid,
    this.ask,
    this.delta,
    this.impliedVolPercent,
    this.openInterest,
    this.volume,
  });

  /// Midpoint of bid and ask, or null without a usable ask.
  double? get mid {
    final a = ask;
    return a == null ? null : (bid + a) / 2;
  }

  /// Bid-ask spread as a percent of the midpoint, or null when unknown.
  double? get spreadPercent {
    final a = ask;
    final m = mid;
    if (a == null || m == null || m <= 0) return null;
    return (a - bid) / m * 100;
  }
}

class ChainSnapshot {
  final String underlying;
  final double spot;

  /// The date the quotes describe. Days to expiration count from here.
  final DateTime asOf;
  final List<OptionQuote> quotes;

  const ChainSnapshot({
    required this.underlying,
    required this.spot,
    required this.asOf,
    required this.quotes,
  });

  /// Calendar days from [asOf] to the quote's expiration.
  int dte(OptionQuote q) {
    final from = DateTime.utc(asOf.year, asOf.month, asOf.day);
    final to = DateTime.utc(
      q.expiration.year,
      q.expiration.month,
      q.expiration.day,
    );
    return to.difference(from).inDays;
  }
}
