enum ImportBroker { tastytrade, thinkorswim, robinhood, fidelity }

enum TradeAction {
  buyToOpen,
  sellToOpen,
  buyToClose,
  sellToClose,
  buy, // equities
  sell, // equities
}

enum InstrumentKind { equity, option }

class ImportedTrade {
  final String id;
  final ImportBroker broker;
  final DateTime dateTime;
  final TradeAction action;
  final InstrumentKind instrumentKind;
  final String underlying; // root symbol e.g. "AAPL"
  final double quantity;
  final double avgPrice; // per share / per contract
  final double netValue; // credit (+) or debit (-) after fees
  final double commissions;
  final double fees;
  // Options-specific
  final double? strike;
  final DateTime? expiry;
  final String? optionType; // "C" or "P"
  final int multiplier;
  final String rawDescription;
  bool selected;

  ImportedTrade({
    required this.id,
    required this.broker,
    required this.dateTime,
    required this.action,
    required this.instrumentKind,
    required this.underlying,
    required this.quantity,
    required this.avgPrice,
    required this.netValue,
    this.commissions = 0,
    this.fees = 0,
    this.strike,
    this.expiry,
    this.optionType,
    this.multiplier = 100,
    this.rawDescription = '',
    this.selected = true,
  });

  bool get isOption => instrumentKind == InstrumentKind.option;
  bool get isOpen =>
      action == TradeAction.buyToOpen || action == TradeAction.sellToOpen;

  String get displaySymbol {
    if (!isOption || expiry == null) return underlying;
    final d = expiry!;
    final mo = d.month.toString().padLeft(2, '0');
    final dy = d.day.toString().padLeft(2, '0');
    return '$underlying ${d.year.toString().substring(2)}$mo$dy '
        '${optionType ?? ''} \$${strike?.toStringAsFixed(0)}';
  }

  String get actionLabel => switch (action) {
    TradeAction.buyToOpen => 'Buy to Open',
    TradeAction.sellToOpen => 'Sell to Open',
    TradeAction.buyToClose => 'Buy to Close',
    TradeAction.sellToClose => 'Sell to Close',
    TradeAction.buy => 'Buy',
    TradeAction.sell => 'Sell',
  };

  Map<String, dynamic> toFirestore() => {
    'broker': broker.name,
    'dateTime': dateTime.toIso8601String(),
    'action': action.name,
    'instrumentKind': instrumentKind.name,
    'underlying': underlying,
    'quantity': quantity,
    'avgPrice': avgPrice,
    'netValue': netValue,
    'commissions': commissions,
    'fees': fees,
    'strike': strike,
    'expiry': expiry?.toIso8601String(),
    'optionType': optionType,
    'multiplier': multiplier,
    'rawDescription': rawDescription,
    'importedAt': DateTime.now().toIso8601String(),
  };
}
