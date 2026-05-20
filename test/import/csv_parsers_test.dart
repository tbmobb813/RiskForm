import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/imported_trade.dart';
import 'package:riskform/services/import/csv_parsers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sample CSV fixtures — each matches the exact real-broker column layout
// ─────────────────────────────────────────────────────────────────────────────

const _tastytradeCSV = '''
Date/Time,Type,Action,Symbol,Instrument Type,Description,Value,Quantity,Average Price,Commissions,Fees,Multiplier,Root Symbol,Underlying Symbol,Expiration Date,Strike Price,Call or Put
2024-01-19T10:30:00+0000,Trade,Sell to Open,AAPL 240119C00150000,Equity Option,Sold 1 AAPL Call,120.00,-1,1.20,-1.00,0.10,100,AAPL,AAPL,2024-01-19,150,C
2024-01-22T14:00:00+0000,Trade,Buy to Close,AAPL 240119C00150000,Equity Option,Bought 1 AAPL Call,-65.00,1,0.65,-1.00,0.10,100,AAPL,AAPL,2024-01-19,150,C
2024-01-25T09:45:00+0000,Trade,Buy,NVDA,Equity,Bought 10 NVDA,-5000.00,10,500.00,-0.00,0.10,1,,NVDA,,,
2024-01-26T09:45:00+0000,Money Movement,Wire,,,Monthly fee,-5.00,,,,,,,,,,
''';

const _tosCSV = '''
DATE,TRANSACTION ID,DESCRIPTION,QUANTITY,SYMBOL,PRICE,COMMISSION,AMOUNT
01/19/2024,TXN001,SELL TO OPEN,-1,AAPL  240119C00150000,1.20,1.00,118.90
01/22/2024,TXN002,BUY TO CLOSE,1,AAPL  240119C00150000,0.65,1.00,-66.00
01/25/2024,TXN003,BUY,10,NVDA,500.00,0.00,-5000.00
''';

// ToS export often has preamble lines before headers
const _tosCSVWithPreamble = '''
"TD AMERITRADE"
"Account Statement"
"Account: 123456789"

DATE,TRANSACTION ID,DESCRIPTION,QUANTITY,SYMBOL,PRICE,COMMISSION,AMOUNT
01/19/2024,TXN001,SELL TO OPEN,-1,AAPL  240119C00150000,1.20,1.00,118.90
01/22/2024,TXN002,BUY TO CLOSE,1,AAPL  240119C00150000,0.65,1.00,-66.00
''';

const _robinhoodCSV = '''
Activity Date,Process Date,Settle Date,Instrument,Description,Trans Code,Quantity,Price,Amount
01/19/2024,01/19/2024,01/23/2024,AAPL240119C00150000,Sell to open,STO,1,1.20,119.35
01/22/2024,01/22/2024,01/24/2024,AAPL240119C00150000,Buy to close,BTC,1,0.65,-65.65
01/25/2024,01/25/2024,01/29/2024,NVDA,Buy shares,BUY,10,500.00,-5000.00
''';

const _fidelityCSV = '''
"Brokerage"

"Account Number","Account Name","Institution"
"Z12345678","INDIVIDUAL - TOD","FIDELITY BROKERAGE SERVICES LLC"

Run Date,Action,Symbol,Security Description,Security Type,Quantity,Price (\$),Commission (\$),Fees (\$),Accrued Interest (\$),Amount (\$),Cash Balance (\$),Settlement Date
01/19/2024,YOU SOLD OPENING TRANSACTION,-AAPL240119C150,APPLE INC JAN 19 2024 150 CALL,Options,-1,2.35,0.65,0.00,,234.35,5234.35,01/23/2024
01/22/2024,YOU BOUGHT CLOSING TRANSACTION,-AAPL240119C150,APPLE INC JAN 19 2024 150 CALL,Options,1,1.10,0.65,0.00,,-110.65,5123.70,01/24/2024
01/25/2024,YOU BOUGHT,NVDA,NVIDIA CORP,Equity,10,500.00,0.00,0.00,,-5000.00,123.70,01/29/2024
01/26/2024,DIVIDEND RECEIVED,AAPL,APPLE INC,Equity,,,,,0.00,35.00,158.70,01/27/2024
''';

// Edge case: Fidelity decimal strike
const _fidelityDecimalStrikeCSV = '''
Run Date,Action,Symbol,Security Description,Security Type,Quantity,Price (\$),Commission (\$),Fees (\$),Accrued Interest (\$),Amount (\$),Cash Balance (\$),Settlement Date
03/15/2024,YOU SOLD OPENING TRANSACTION,-SPY240315P502.5,SPY MAR 15 2024 502.5 PUT,Options,-2,3.50,1.30,0.00,,698.70,5000.00,03/19/2024
''';

void main() {
  // ── tastytrade ─────────────────────────────────────────────────────────────
  group('parseTastytrade', () {
    late List<ImportedTrade> trades;

    setUp(() => trades = parseTastytrade(_tastytradeCSV));

    test('parses correct number of trades (skips non-trade rows)', () {
      // Wire transfer has no valid action → excluded
      expect(trades.length, 3);
    });

    test('sell to open — options fields', () {
      final t = trades[0];
      expect(t.action, TradeAction.sellToOpen);
      expect(t.broker, ImportBroker.tastytrade);
      expect(t.instrumentKind, InstrumentKind.option);
      expect(t.underlying, 'AAPL');
      expect(t.strike, 150.0);
      expect(t.optionType, 'C');
      expect(t.expiry, DateTime(2024, 1, 19));
      expect(t.quantity, 1.0);
      expect(t.avgPrice, 1.20);
      expect(t.netValue, 120.00);
      expect(t.commissions, 1.00);
      expect(t.multiplier, 100);
    });

    test('buy to close', () {
      final t = trades[1];
      expect(t.action, TradeAction.buyToClose);
      expect(t.netValue, -65.00);
    });

    test('equity buy', () {
      final t = trades[2];
      expect(t.action, TradeAction.buy);
      expect(t.instrumentKind, InstrumentKind.equity);
      expect(t.underlying, 'NVDA');
      expect(t.quantity, 10.0);
    });
  });

  // ── thinkorSwim ───────────────────────────────────────────────────────────
  group('parseThinkorswim', () {
    test('parses standard CSV', () {
      final trades = parseThinkorswim(_tosCSV);
      expect(trades.length, 3);

      final sto = trades[0];
      expect(sto.action, TradeAction.sellToOpen);
      expect(sto.broker, ImportBroker.thinkorswim);
      expect(sto.instrumentKind, InstrumentKind.option);
      expect(sto.underlying, 'AAPL');
      expect(sto.strike, 150.0);
      expect(sto.optionType, 'C');
      expect(sto.expiry, DateTime(2024, 1, 19));
    });

    test('skips preamble lines and still parses', () {
      final trades = parseThinkorswim(_tosCSVWithPreamble);
      expect(trades.length, 2);
      expect(trades[0].underlying, 'AAPL');
    });

    test('OCC symbol — 8-digit padded strike divided by 1000', () {
      final trades = parseThinkorswim(_tosCSV);
      // AAPL  240119C00150000 → strike = 150000 / 1000 = 150.0
      expect(trades[0].strike, 150.0);
    });

    test('equity buy', () {
      final trades = parseThinkorswim(_tosCSV);
      final eq = trades[2];
      expect(eq.instrumentKind, InstrumentKind.equity);
      expect(eq.underlying, 'NVDA');
    });

    test('date parsing MM/DD/YYYY', () {
      final trades = parseThinkorswim(_tosCSV);
      expect(trades[0].dateTime, DateTime(2024, 1, 19));
    });
  });

  // ── Robinhood ─────────────────────────────────────────────────────────────
  group('parseRobinhood', () {
    late List<ImportedTrade> trades;

    setUp(() => trades = parseRobinhood(_robinhoodCSV));

    test('parses correct trade count', () {
      expect(trades.length, 3);
    });

    test('STO maps to sellToOpen', () {
      expect(trades[0].action, TradeAction.sellToOpen);
      expect(trades[0].broker, ImportBroker.robinhood);
    });

    test('BTC maps to buyToClose', () {
      expect(trades[1].action, TradeAction.buyToClose);
    });

    test('plain BUY maps to buy for equity', () {
      expect(trades[2].action, TradeAction.buy);
      expect(trades[2].instrumentKind, InstrumentKind.equity);
    });

    test('OCC symbol in Instrument field is parsed for options', () {
      // AAPL240119C00150000 → OCC: strike = 150.0
      expect(trades[0].instrumentKind, InstrumentKind.option);
      expect(trades[0].underlying, 'AAPL');
      expect(trades[0].strike, 150.0);
    });

    test('date parsing MM/DD/YYYY', () {
      expect(trades[0].dateTime, DateTime(2024, 1, 19));
    });
  });

  // ── Fidelity ──────────────────────────────────────────────────────────────
  group('parseFidelity', () {
    late List<ImportedTrade> trades;

    setUp(() => trades = parseFidelity(_fidelityCSV));

    test('skips preamble and dividend rows — returns 3 trades', () {
      // DIVIDEND RECEIVED has no valid action → excluded
      expect(trades.length, 3);
    });

    test('YOU SOLD OPENING → sellToOpen', () {
      final t = trades[0];
      expect(t.action, TradeAction.sellToOpen);
      expect(t.broker, ImportBroker.fidelity);
      expect(t.instrumentKind, InstrumentKind.option);
      expect(t.underlying, 'AAPL');
    });

    test('YOU BOUGHT CLOSING → buyToClose', () {
      expect(trades[1].action, TradeAction.buyToClose);
    });

    test('YOU BOUGHT → buy (equity)', () {
      final t = trades[2];
      expect(t.action, TradeAction.buy);
      expect(t.instrumentKind, InstrumentKind.equity);
      expect(t.underlying, 'NVDA');
    });

    test('Fidelity dash-prefix symbol: -AAPL240119C150', () {
      final t = trades[0];
      expect(t.underlying, 'AAPL');
      expect(t.strike, 150.0);
      expect(t.optionType, 'C');
      expect(t.expiry, DateTime(2024, 1, 19));
    });

    test('date parsing MM/DD/YYYY', () {
      expect(trades[0].dateTime, DateTime(2024, 1, 19));
    });

    test('net value from Amount column', () {
      // First row: Amount = 234.35 (credit)
      expect(trades[0].netValue, 234.35);
      // Second row: -110.65 (debit)
      expect(trades[1].netValue, -110.65);
    });

    test('decimal strike — -SPY240315P502.5', () {
      final trades = parseFidelity(_fidelityDecimalStrikeCSV);
      expect(trades.length, 1);
      expect(trades[0].underlying, 'SPY');
      expect(trades[0].strike, 502.5);
      expect(trades[0].optionType, 'P');
      expect(trades[0].quantity, 2.0); // abs of -2
    });

    test('empty CSV returns empty list', () {
      expect(parseFidelity(''), isEmpty);
    });

    test('no header row returns empty list', () {
      expect(parseFidelity('garbage,data\n1,2,3'), isEmpty);
    });
  });

  // ── Cross-broker ──────────────────────────────────────────────────────────
  group('Cross-broker sanity', () {
    test('all parsers return empty list for empty input', () {
      expect(parseTastytrade(''), isEmpty);
      expect(parseThinkorswim(''), isEmpty);
      expect(parseRobinhood(''), isEmpty);
      expect(parseFidelity(''), isEmpty);
    });

    test('all ImportedTrade IDs are unique within a single parse', () {
      for (final trades in [
        parseTastytrade(_tastytradeCSV),
        parseThinkorswim(_tosCSV),
        parseRobinhood(_robinhoodCSV),
        parseFidelity(_fidelityCSV),
      ]) {
        final ids = trades.map((t) => t.id).toSet();
        expect(ids.length, trades.length, reason: 'Duplicate IDs found');
      }
    });

    test('quantity is always non-negative (abs applied)', () {
      for (final trades in [
        parseTastytrade(_tastytradeCSV),
        parseThinkorswim(_tosCSV),
        parseRobinhood(_robinhoodCSV),
        parseFidelity(_fidelityCSV),
      ]) {
        for (final t in trades) {
          expect(
            t.quantity,
            greaterThanOrEqualTo(0),
            reason: '${t.broker} ${t.underlying} has negative qty',
          );
        }
      }
    });
  });
}
