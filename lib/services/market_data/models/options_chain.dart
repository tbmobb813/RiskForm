import 'option_contract.dart';

/// Represents a full options chain for a ticker
class OptionsChain {
  final String ticker;
  final List<OptionContract> calls;
  final List<OptionContract> puts;
  final List<DateTime> expirations;

  const OptionsChain({
    required this.ticker,
    required this.calls,
    required this.puts,
    required this.expirations,
  });

  factory OptionsChain.fromTradierJson(String ticker, Map<String, dynamic> json) {
    final options = json['options']?['option'];

    if (options == null) {
      return OptionsChain(ticker: ticker, calls: [], puts: [], expirations: []);
    }

    final optionsList = options is List ? options : [options];

    final calls = <OptionContract>[];
    final puts = <OptionContract>[];
    final expirationSet = <DateTime>{};

    for (final opt in optionsList) {
      final contract = OptionContract.fromTradierJson(opt);
      expirationSet.add(contract.expiration);

      if (contract.type == OptionType.call) {
        calls.add(contract);
      } else {
        puts.add(contract);
      }
    }

    // Sort by strike
    calls.sort((a, b) => a.strike.compareTo(b.strike));
    puts.sort((a, b) => a.strike.compareTo(b.strike));

    // Sort expirations chronologically
    final expirations = expirationSet.toList()..sort();

    return OptionsChain(
      ticker: ticker,
      calls: calls,
      puts: puts,
      expirations: expirations,
    );
  }

  /// Get contracts for a specific expiration date
  OptionsChain filterByExpiration(DateTime expiration) {
    final filteredCalls = calls.where((c) => c.expiration == expiration).toList();
    final filteredPuts = puts.where((p) => p.expiration == expiration).toList();

    return OptionsChain(
      ticker: ticker,
      calls: filteredCalls,
      puts: filteredPuts,
      expirations: [expiration],
    );
  }

  /// Get the nearest expiration date
  DateTime? get nearestExpiration => expirations.isEmpty ? null : expirations.first;

  /// Get contracts near a specific strike price (within delta)
  List<OptionContract> getContractsNearStrike(double strike, {double delta = 5.0, OptionType? type}) {
    final contracts = type == OptionType.call
        ? calls
        : type == OptionType.put
            ? puts
            : [...calls, ...puts];

    return contracts
        .where((c) => (c.strike - strike).abs() <= delta)
        .toList();
  }

  /// Find liquid contracts only
  OptionsChain get liquidOnly {
    return OptionsChain(
      ticker: ticker,
      calls: calls.where((c) => c.isLiquid).toList(),
      puts: puts.where((p) => p.isLiquid).toList(),
      expirations: expirations,
    );
  }

  @override
  String toString() {
    return 'OptionsChain($ticker: ${calls.length} calls, ${puts.length} puts, '
        '${expirations.length} expirations)';
  }
}
