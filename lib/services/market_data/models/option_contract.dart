import 'greeks.dart';

/// Represents a single option contract
class OptionContract {
  final String symbol; // OCC symbol (e.g., "AAPL230120C00150000")
  final double strike;
  final OptionType type;
  final DateTime expiration;
  final double bid;
  final double ask;
  final double last;
  final double volume;
  final double openInterest;
  final Greeks? greeks;

  const OptionContract({
    required this.symbol,
    required this.strike,
    required this.type,
    required this.expiration,
    required this.bid,
    required this.ask,
    required this.last,
    required this.volume,
    required this.openInterest,
    this.greeks,
  });

  factory OptionContract.fromTradierJson(Map<String, dynamic> json) {
    return OptionContract(
      symbol: json['symbol'] as String? ?? '',
      strike: (json['strike'] as num?)?.toDouble() ?? 0.0,
      type: (json['option_type'] as String?)?.toLowerCase() == 'call'
          ? OptionType.call
          : OptionType.put,
      expiration: DateTime.parse(json['expiration_date'] as String? ?? ''),
      bid: (json['bid'] as num?)?.toDouble() ?? 0.0,
      ask: (json['ask'] as num?)?.toDouble() ?? 0.0,
      last: (json['last'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      openInterest: (json['open_interest'] as num?)?.toDouble() ?? 0.0,
      greeks: json['greeks'] != null ? Greeks.fromTradierJson(json['greeks']) : null,
    );
  }

  /// Midpoint between bid and ask
  double get midpoint => (bid + ask) / 2;

  /// Whether this contract has sufficient liquidity
  bool get isLiquid => openInterest >= 100 && volume >= 10;

  /// Days to expiration
  int get dte {
    final now = DateTime.now();
    return expiration.difference(now).inDays;
  }

  /// Display name (e.g., "AAPL $150 Call 20 DTE")
  String get displayName {
    final underlying = symbol.substring(0, symbol.length - 15); // Extract ticker
    return '$underlying \$${strike.toStringAsFixed(0)} ${type.name.toUpperCase()} $dte DTE';
  }

  @override
  String toString() {
    return 'OptionContract($displayName, bid: \$${bid.toStringAsFixed(2)}, '
        'ask: \$${ask.toStringAsFixed(2)}, OI: ${openInterest.toInt()})';
  }
}

enum OptionType { call, put }
