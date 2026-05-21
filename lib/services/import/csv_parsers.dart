import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../../models/imported_trade.dart';

// ── Fidelity symbol parser ─────────────────────────────────────────────────────
// Format: "-AAPL240119C150"  (dash prefix, YYMMDD, C|P, strike without padding)
class _FidelitySymbol {
  final String underlying;
  final DateTime expiry;
  final String type; // "C" or "P"
  final double strike;
  _FidelitySymbol(this.underlying, this.expiry, this.type, this.strike);
}

_FidelitySymbol? _parseFidelitySymbol(String raw) {
  // Strip leading dash
  final s = raw.startsWith('-') ? raw.substring(1) : raw;
  // Pattern: letters + 6-digit date + C|P + numeric strike (may include decimal)
  final m = RegExp(r'^([A-Z]+)(\d{6})([CP])([\d.]+)$').firstMatch(s);
  if (m == null) return null;
  final root = m.group(1)!;
  final dateStr = m.group(2)!;
  final type = m.group(3)!;
  final strike = double.tryParse(m.group(4)!);
  if (strike == null) return null;
  final y = 2000 + int.parse(dateStr.substring(0, 2));
  final mo = int.parse(dateStr.substring(2, 4));
  final d = int.parse(dateStr.substring(4, 6));
  return _FidelitySymbol(root, DateTime(y, mo, d), type, strike);
}

const _uuid = Uuid();

// ── Shared helpers ────────────────────────────────────────────────────────────

double _d(dynamic v) {
  if (v == null) return 0;
  final s = v.toString().replaceAll(r'$', '').replaceAll(',', '').trim();
  return double.tryParse(s) ?? 0;
}

int _i(dynamic v) => int.tryParse(v?.toString().trim() ?? '') ?? 0;

TradeAction? _parseAction(String raw) {
  final s = raw.toUpperCase().trim();
  if (s.contains('BUY TO OPEN') || s == 'BTO') return TradeAction.buyToOpen;
  if (s.contains('SELL TO OPEN') || s == 'STO') return TradeAction.sellToOpen;
  if (s.contains('BUY TO CLOSE') || s == 'BTC') return TradeAction.buyToClose;
  if (s.contains('SELL TO CLOSE') || s == 'STC') return TradeAction.sellToClose;
  if (s == 'BUY' || s == 'B') return TradeAction.buy;
  if (s == 'SELL' || s == 'S') return TradeAction.sell;
  return null;
}

List<List<dynamic>> _parseCsv(String raw) {
  // Skip empty lines and handle Windows line endings
  final cleaned = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return const CsvToListConverter(eol: '\n').convert(cleaned);
}

// ── OCC symbol parser (used by ToS) ──────────────────────────────────────────
// Format: "AAPL  240119C00150000"  or  "AAPL 240119P00145000"
class _OccParsed {
  final String underlying;
  final DateTime expiry;
  final String type; // "C" or "P"
  final double strike;
  _OccParsed(this.underlying, this.expiry, this.type, this.strike);
}

_OccParsed? _parseOcc(String symbol) {
  // Strip spaces, expect at least 15 chars after root
  final clean = symbol.replaceAll(' ', '');
  // Find where the date starts — 6 digit run after the root letters
  final match = RegExp(r'^([A-Z]+)(\d{6})([CP])(\d{8})$').firstMatch(clean);
  if (match == null) return null;
  final root = match.group(1)!;
  final dateStr = match.group(2)!;
  final type = match.group(3)!;
  final strikeRaw = int.tryParse(match.group(4)!) ?? 0;
  final strike = strikeRaw / 1000.0;
  final y = 2000 + int.parse(dateStr.substring(0, 2));
  final m = int.parse(dateStr.substring(2, 4));
  final d = int.parse(dateStr.substring(4, 6));
  return _OccParsed(root, DateTime(y, m, d), type, strike);
}

// ── tastytrade parser ─────────────────────────────────────────────────────────
// Expected headers (order may vary):
// Date/Time, Type, Action, Symbol, Instrument Type, Description,
// Value, Quantity, Average Price, Commissions, Fees, Multiplier,
// Root Symbol, Underlying Symbol, Expiration Date, Strike Price, Call or Put

List<ImportedTrade> parseTastytrade(String csvContent) {
  final rows = _parseCsv(csvContent);
  if (rows.length < 2) return [];

  final headers = rows.first.map((h) => h.toString().trim()).toList();
  int col(String name) =>
      headers.indexWhere((h) => h.toLowerCase() == name.toLowerCase());

  final iDateTime = col('Date/Time');
  final iAction = col('Action');
  final iType = col('Instrument Type');
  final iDesc = col('Description');
  final iValue = col('Value');
  final iQty = col('Quantity');
  final iAvgPrice = col('Average Price');
  final iComm = col('Commissions');
  final iFees = col('Fees');
  final iMult = col('Multiplier');
  final iUnderlying = col('Underlying Symbol');
  final iExpiry = col('Expiration Date');
  final iStrike = col('Strike Price');
  final iCallPut = col('Call or Put');

  final trades = <ImportedTrade>[];

  for (final row in rows.skip(1)) {
    if (row.length <= iAction || row.length <= iDateTime) continue;

    final action = _parseAction(row[iAction].toString());
    if (action == null) continue; // skip non-trade rows (fees, interest, etc.)

    final typeStr = iType >= 0 ? row[iType].toString().toUpperCase() : '';
    final isOption = typeStr.contains('OPTION');

    DateTime? dt;
    try {
      dt = DateTime.parse(row[iDateTime].toString().trim());
    } catch (_) {
      continue;
    }

    DateTime? expiry;
    if (iExpiry >= 0 && row[iExpiry].toString().trim().isNotEmpty) {
      try {
        expiry = DateTime.parse(row[iExpiry].toString().trim());
      } catch (_) {}
    }

    final underlying =
        iUnderlying >= 0 && row[iUnderlying].toString().trim().isNotEmpty
        ? row[iUnderlying].toString().trim()
        : '';
    if (underlying.isEmpty) continue;

    trades.add(
      ImportedTrade(
        id: _uuid.v4(),
        broker: ImportBroker.tastytrade,
        dateTime: dt,
        action: action,
        instrumentKind: isOption
            ? InstrumentKind.option
            : InstrumentKind.equity,
        underlying: underlying,
        quantity: _d(iQty >= 0 ? row[iQty] : null).abs(),
        avgPrice: _d(iAvgPrice >= 0 ? row[iAvgPrice] : null).abs(),
        netValue: _d(iValue >= 0 ? row[iValue] : null),
        commissions: _d(iComm >= 0 ? row[iComm] : null).abs(),
        fees: _d(iFees >= 0 ? row[iFees] : null).abs(),
        multiplier: iMult >= 0 ? (_i(row[iMult]).clamp(1, 1000)) : 100,
        strike: iStrike >= 0 ? _d(row[iStrike]) : null,
        expiry: expiry,
        optionType: iCallPut >= 0 && row[iCallPut].toString().trim().isNotEmpty
            ? row[iCallPut].toString().trim().substring(0, 1).toUpperCase()
            : null,
        rawDescription: iDesc >= 0 ? row[iDesc].toString() : '',
      ),
    );
  }

  return trades;
}

// ── thinkorSwim / TD Ameritrade parser ────────────────────────────────────────
// Expected headers: DATE, TRANSACTION ID, DESCRIPTION, QUANTITY,
// SYMBOL, PRICE, COMMISSION, AMOUNT
// Options symbol is OCC format embedded in SYMBOL column.

List<ImportedTrade> parseThinkorswim(String csvContent) {
  // TOS exports sometimes have metadata lines before the CSV header.
  // Find the actual header row containing "DATE" or "Date".
  final lines = csvContent
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');

  int headerIdx = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].toUpperCase().contains('DATE') &&
        lines[i].toUpperCase().contains('SYMBOL')) {
      headerIdx = i;
      break;
    }
  }
  if (headerIdx < 0) return [];

  final csvBody = lines.sublist(headerIdx).join('\n');
  final rows = _parseCsv(csvBody);
  if (rows.length < 2) return [];

  final headers = rows.first
      .map((h) => h.toString().trim().toUpperCase())
      .toList();
  int col(String name) => headers.indexWhere((h) => h == name.toUpperCase());

  final iDate = col('DATE');
  final iDesc = col('DESCRIPTION');
  final iQty = col('QUANTITY');
  final iSymbol = col('SYMBOL');
  final iPrice = col('PRICE');
  final iComm = col('COMMISSION');
  final iAmount = col('AMOUNT');

  final trades = <ImportedTrade>[];

  for (final row in rows.skip(1)) {
    if (row.isEmpty || iSymbol < 0 || row.length <= iSymbol) continue;

    final symbol = row[iSymbol].toString().trim();
    if (symbol.isEmpty) continue;

    final desc = iDesc >= 0 ? row[iDesc].toString() : '';

    // Infer action from description
    final action = _parseAction(desc);
    if (action == null) continue;

    DateTime? dt;
    if (iDate >= 0) {
      try {
        dt = DateTime.parse(row[iDate].toString().trim());
      } catch (_) {
        // TOS uses MM/DD/YYYY
        final parts = row[iDate].toString().trim().split('/');
        if (parts.length == 3) {
          try {
            dt = DateTime(
              int.parse(parts[2]),
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          } catch (_) {}
        }
      }
    }
    if (dt == null) continue;

    // Try OCC parse for options
    final occ = _parseOcc(symbol);
    final isOption = occ != null;
    final underlying = occ?.underlying ?? symbol;

    trades.add(
      ImportedTrade(
        id: _uuid.v4(),
        broker: ImportBroker.thinkorswim,
        dateTime: dt,
        action: action,
        instrumentKind: isOption
            ? InstrumentKind.option
            : InstrumentKind.equity,
        underlying: underlying,
        quantity: _d(iQty >= 0 ? row[iQty] : null).abs(),
        avgPrice: _d(iPrice >= 0 ? row[iPrice] : null).abs(),
        netValue: _d(iAmount >= 0 ? row[iAmount] : null),
        commissions: _d(iComm >= 0 ? row[iComm] : null).abs(),
        strike: occ?.strike,
        expiry: occ?.expiry,
        optionType: occ?.type,
        rawDescription: desc,
      ),
    );
  }

  return trades;
}

// ── Robinhood parser ──────────────────────────────────────────────────────────
// Headers: Activity Date, Process Date, Settle Date, Instrument,
// Description, Trans Code, Quantity, Price, Amount

List<ImportedTrade> parseRobinhood(String csvContent) {
  final rows = _parseCsv(csvContent);
  if (rows.length < 2) return [];

  final headers = rows.first.map((h) => h.toString().trim()).toList();
  int col(String name) =>
      headers.indexWhere((h) => h.toLowerCase() == name.toLowerCase());

  final iDate = col('Activity Date');
  final iInstrument = col('Instrument');
  final iDesc = col('Description');
  final iCode = col('Trans Code');
  final iQty = col('Quantity');
  final iPrice = col('Price');
  final iAmount = col('Amount');

  final trades = <ImportedTrade>[];

  for (final row in rows.skip(1)) {
    if (row.isEmpty) continue;

    final code = iCode >= 0 ? row[iCode].toString().trim().toUpperCase() : '';
    // Robinhood trans codes: Buy, Sell, OEXP (expiry), OASGN (assignment)
    if (!['BUY', 'SELL', 'STO', 'BTO', 'STC', 'BTC'].contains(code)) continue;

    final instrument = iInstrument >= 0
        ? row[iInstrument].toString().trim()
        : '';
    if (instrument.isEmpty) continue;

    final desc = iDesc >= 0 ? row[iDesc].toString() : '';

    // Infer action: Robinhood uses Trans Code as BUY/SELL for equities,
    // and sometimes STO/BTO/STC/BTC for options
    TradeAction action;
    if (code == 'STO') {
      action = TradeAction.sellToOpen;
    } else if (code == 'BTO') {
      action = TradeAction.buyToOpen;
    } else if (code == 'STC') {
      action = TradeAction.sellToClose;
    } else if (code == 'BTC') {
      action = TradeAction.buyToClose;
    } else if (code == 'BUY') {
      // Could be equity buy or option open — check description
      action = desc.toUpperCase().contains('OPEN')
          ? TradeAction.buyToOpen
          : TradeAction.buy;
    } else {
      action = desc.toUpperCase().contains('CLOSE')
          ? TradeAction.sellToClose
          : TradeAction.sell;
    }

    DateTime? dt;
    if (iDate >= 0) {
      try {
        dt = DateTime.parse(row[iDate].toString().trim());
      } catch (_) {
        final parts = row[iDate].toString().trim().split('/');
        if (parts.length == 3) {
          try {
            dt = DateTime(
              int.parse(parts[2]),
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          } catch (_) {}
        }
      }
    }
    if (dt == null) continue;

    // Try OCC parse (Robinhood sometimes uses OCC in Instrument field)
    final occ = _parseOcc(instrument);
    final isOption = occ != null;
    final underlying = occ?.underlying ?? instrument;

    trades.add(
      ImportedTrade(
        id: _uuid.v4(),
        broker: ImportBroker.robinhood,
        dateTime: dt,
        action: action,
        instrumentKind: isOption
            ? InstrumentKind.option
            : InstrumentKind.equity,
        underlying: underlying,
        quantity: _d(iQty >= 0 ? row[iQty] : null).abs(),
        avgPrice: _d(iPrice >= 0 ? row[iPrice] : null).abs(),
        netValue: _d(iAmount >= 0 ? row[iAmount] : null),
        strike: occ?.strike,
        expiry: occ?.expiry,
        optionType: occ?.type,
        rawDescription: desc,
      ),
    );
  }

  return trades;
}

// ── Fidelity parser ────────────────────────────────────────────────────────────
// Headers: Run Date,Action,Symbol,Security Description,Security Type,
//          Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),
//          Amount ($),Cash Balance ($),Settlement Date
//
// Preamble: Fidelity prepends ~5 metadata lines before the header row.
// Options symbol: "-AAPL240119C150" (dash-prefixed, short strike)
// Action strings: "YOU BOUGHT OPENING TRANSACTION", "YOU SOLD CLOSING TRANSACTION", etc.
// Dates: MM/DD/YYYY

List<ImportedTrade> parseFidelity(String csvContent) {
  final lines = csvContent
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');

  // Skip preamble — find first row that starts with "Run Date" (the header)
  int headerIdx = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].trim().toLowerCase().startsWith('run date')) {
      headerIdx = i;
      break;
    }
  }
  if (headerIdx < 0) return [];

  final csvBody = lines.sublist(headerIdx).join('\n');
  final rows = _parseCsv(csvBody);
  if (rows.length < 2) return [];

  final headers = rows.first
      .map((h) => h.toString().trim().toLowerCase())
      .toList();
  int col(String name) =>
      headers.indexWhere((h) => h.contains(name.toLowerCase()));

  final iDate = col('run date');
  final iAction = col('action');
  final iSymbol = col('symbol');
  final iSecType = col('security type');
  final iQty = col('quantity');
  final iPrice = col('price');
  final iComm = col('commission');
  final iFees = col('fees');
  final iAmount = col('amount');

  final trades = <ImportedTrade>[];

  for (final row in rows.skip(1)) {
    if (row.isEmpty || iAction < 0 || row.length <= iAction) continue;

    final actionRaw = iAction >= 0 ? row[iAction].toString().toUpperCase() : '';

    // Only process opening/closing option and equity trades
    final action = _parseFidelityAction(actionRaw);
    if (action == null) continue;

    final symbol = iSymbol >= 0 ? row[iSymbol].toString().trim() : '';
    if (symbol.isEmpty) continue;

    final secType = iSecType >= 0 ? row[iSecType].toString().toUpperCase() : '';
    final isOption = secType.contains('OPTION') || symbol.startsWith('-');

    // Parse date MM/DD/YYYY
    DateTime? dt;
    if (iDate >= 0) {
      final parts = row[iDate].toString().trim().split('/');
      if (parts.length == 3) {
        try {
          dt = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } catch (_) {}
      }
    }
    if (dt == null) continue;

    // Parse Fidelity-specific option symbol
    final fid = isOption ? _parseFidelitySymbol(symbol) : null;
    final underlying = fid?.underlying ?? symbol;

    final qty = _d(iQty >= 0 ? row[iQty] : null).abs();
    final price = _d(iPrice >= 0 ? row[iPrice] : null).abs();
    final amount = _d(iAmount >= 0 ? row[iAmount] : null);
    final comm = _d(iComm >= 0 ? row[iComm] : null).abs();
    final fees = _d(iFees >= 0 ? row[iFees] : null).abs();

    trades.add(
      ImportedTrade(
        id: _uuid.v4(),
        broker: ImportBroker.fidelity,
        dateTime: dt,
        action: action,
        instrumentKind: isOption
            ? InstrumentKind.option
            : InstrumentKind.equity,
        underlying: underlying,
        quantity: qty,
        avgPrice: price,
        netValue: amount,
        commissions: comm,
        fees: fees,
        strike: fid?.strike,
        expiry: fid?.expiry,
        optionType: fid?.type,
        rawDescription: actionRaw,
      ),
    );
  }

  return trades;
}

TradeAction? _parseFidelityAction(String action) {
  if (action.contains('SOLD') && action.contains('OPENING')) {
    return TradeAction.sellToOpen;
  }
  if (action.contains('SOLD') && action.contains('CLOSING')) {
    return TradeAction.sellToClose;
  }
  if (action.contains('BOUGHT') && action.contains('OPENING')) {
    return TradeAction.buyToOpen;
  }
  if (action.contains('BOUGHT') && action.contains('CLOSING')) {
    return TradeAction.buyToClose;
  }
  if (action.contains('YOU BOUGHT')) return TradeAction.buy;
  if (action.contains('YOU SOLD')) return TradeAction.sell;
  return null;
}
