import 'option_chain.dart';

class ChainParseResult {
  final List<OptionQuote> quotes;

  /// One message per rejected line, for example "Line 4: bad strike".
  final List<String> errors;

  const ChainParseResult({required this.quotes, required this.errors});
}

/// Parses a pasted option chain: a header row followed by one quote per line,
/// separated by commas or tabs. Column names are matched flexibly.
///
/// Required columns: strike, bid, and either an expiration date or DTE.
/// Optional: ask, delta, IV, open interest, volume, and put/call type.
/// Without a type column every row is treated as [defaultRight].
///
/// IV values of 3 or less are read as fractions (0.32 means 32%).
class ChainParser {
  const ChainParser();

  static const _aliases = <String, Set<String>>{
    'strike': {'strike', 'strikeprice'},
    'expiration': {'expiration', 'expirationdate', 'expiry', 'exp', 'expdate'},
    'dte': {'dte', 'daystoexpiration'},
    'bid': {'bid'},
    'ask': {'ask'},
    'delta': {'delta'},
    'iv': {'iv', 'impliedvolatility', 'impvol', 'ivpercent'},
    'oi': {'oi', 'openinterest'},
    'volume': {'volume', 'vol'},
    'right': {'type', 'right', 'putcall', 'optiontype', 'side'},
  };

  ChainParseResult parse(
    String text, {
    required DateTime asOf,
    OptionRight defaultRight = OptionRight.put,
  }) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const ChainParseResult(quotes: [], errors: ['Nothing to parse.']);
    }

    final delimiter = lines.first.contains('\t') ? '\t' : ',';
    final columns = _mapColumns(lines.first.split(delimiter));

    final missing = [
      if (!columns.containsKey('strike')) 'strike',
      if (!columns.containsKey('bid')) 'bid',
      if (!columns.containsKey('expiration') && !columns.containsKey('dte'))
        'expiration or DTE',
    ];
    if (missing.isNotEmpty) {
      return ChainParseResult(
        quotes: const [],
        errors: ['Header row is missing: ${missing.join(', ')}.'],
      );
    }

    final quotes = <OptionQuote>[];
    final errors = <String>[];

    for (var n = 1; n < lines.length; n++) {
      final cells = lines[n].split(delimiter).map((c) => c.trim()).toList();
      String? cell(String key) {
        final i = columns[key];
        return (i == null || i >= cells.length) ? null : cells[i];
      }

      final label = 'Line ${n + 1}';

      final strike = _number(cell('strike'));
      if (strike == null || strike <= 0) {
        errors.add('$label: bad strike.');
        continue;
      }
      final bid = _number(cell('bid'));
      if (bid == null || bid < 0) {
        errors.add('$label: bad bid.');
        continue;
      }

      final expiration = _expiration(cell('expiration'), cell('dte'), asOf);
      if (expiration == null) {
        errors.add('$label: bad expiration or DTE.');
        continue;
      }

      final ask = _number(cell('ask'));
      if (ask != null && ask < bid) {
        errors.add('$label: ask is below bid.');
        continue;
      }

      final right = columns.containsKey('right')
          ? _right(cell('right'))
          : defaultRight;
      if (right == null) {
        errors.add('$label: type must be put or call.');
        continue;
      }

      final delta = _number(cell('delta'));
      final iv = _number(cell('iv'));

      quotes.add(
        OptionQuote(
          right: right,
          strike: strike,
          expiration: expiration,
          bid: bid,
          ask: ask,
          delta: delta?.abs(),
          impliedVolPercent: iv == null ? null : (iv <= 3 ? iv * 100 : iv),
          openInterest: _number(cell('oi'))?.round(),
          volume: _number(cell('volume'))?.round(),
        ),
      );
    }

    return ChainParseResult(quotes: quotes, errors: errors);
  }

  Map<String, int> _mapColumns(List<String> header) {
    final columns = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final name = header[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      for (final entry in _aliases.entries) {
        if (entry.value.contains(name)) {
          columns.putIfAbsent(entry.key, () => i);
        }
      }
    }
    return columns;
  }

  double? _number(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[\$,%\s]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  OptionRight? _right(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'put':
      case 'p':
        return OptionRight.put;
      case 'call':
      case 'c':
        return OptionRight.call;
      default:
        return null;
    }
  }

  DateTime? _expiration(String? date, String? dte, DateTime asOf) {
    if (date != null && date.isNotEmpty) {
      final iso = DateTime.tryParse(date);
      if (iso != null) return DateTime.utc(iso.year, iso.month, iso.day);

      final us = RegExp(
        r'^(\d{1,2})/(\d{1,2})/(\d{2}|\d{4})$',
      ).firstMatch(date);
      if (us != null) {
        final month = int.parse(us.group(1)!);
        final day = int.parse(us.group(2)!);
        var year = int.parse(us.group(3)!);
        if (year < 100) year += 2000;
        if (month < 1 || month > 12 || day < 1 || day > 31) return null;
        return DateTime.utc(year, month, day);
      }
      return null;
    }

    final days = _number(dte);
    if (days == null || days < 0) return null;
    return DateTime.utc(
      asOf.year,
      asOf.month,
      asOf.day,
    ).add(Duration(days: days.round()));
  }
}
