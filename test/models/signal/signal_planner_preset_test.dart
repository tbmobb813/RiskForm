import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/signal_model.dart';
import 'package:riskform/models/signal_planner_preset.dart';

SignalModel _signal({
  String ticker = 'AAPL',
  SignalType signal = SignalType.buy,
  int confidence = 75,
  String timeframe = '1-4 WEEKS',
  String entryZone = '\$148-152',
  String target = '\$160',
  String stop = '\$142',
  String? optionsEdge,
  RegimeType regime = RegimeType.riskOn,
}) => SignalModel(
  ticker: ticker,
  signal: signal,
  confidence: confidence,
  timeframe: timeframe,
  entryZone: entryZone,
  target: target,
  stop: stop,
  thesis: 'Test thesis.',
  macroContext: 'Test macro.',
  optionsEdge: optionsEdge,
  keyRisks: [],
  dataSourcesUsed: [],
  regime: regime,
  macroScore: 20,
  technicalScore: 30,
  sentimentScore: 10,
  compositeScore: 20,
);

void main() {
  // ── Strategy inference ────────────────────────────────────────────────────
  group('Strategy inference from options_edge', () {
    test('CSP keyword → csp', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Sell cash-secured put, 30 delta, 21 DTE'),
      );
      expect(p.strategyId, 'csp');
    });

    test('CSP abbreviation → csp', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'CSP at the 30 delta, collect premium'),
      );
      expect(p.strategyId, 'csp');
    });

    test('Wheel keyword → csp (Wheel entry leg)', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Start the Wheel with a put'),
      );
      expect(p.strategyId, 'csp');
    });

    test('Covered Call keyword → cc', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Sell covered call against existing shares'),
      );
      expect(p.strategyId, 'cc');
    });

    test('PMCC keyword → long_call', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'PMCC: buy LEAPS, sell short-dated call'),
      );
      expect(p.strategyId, 'long_call');
    });

    test('Poor man keyword → long_call', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Poor man covered call setup'),
      );
      expect(p.strategyId, 'long_call');
    });

    test('Debit spread keyword → debit_spread', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Bull call debit spread, 1:2 R/R'),
      );
      expect(p.strategyId, 'debit_spread');
    });

    test('Credit spread keyword → credit_spread', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Sell credit spread below support'),
      );
      expect(p.strategyId, 'credit_spread');
    });

    test('Iron condor keyword → credit_spread', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Iron condor between 140/145 and 160/165'),
      );
      expect(p.strategyId, 'credit_spread');
    });

    test('Long call keyword → long_call', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Buy call, 45 DTE, target 10% move'),
      );
      expect(p.strategyId, 'long_call');
    });

    test('Long put keyword → long_put', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Long put hedge, 30 delta'),
      );
      expect(p.strategyId, 'long_put');
    });
  });

  group('Strategy fallback from signal direction (null options_edge)', () {
    test('BUY → long_call', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(signal: SignalType.buy, optionsEdge: null),
      );
      expect(p.strategyId, 'long_call');
    });

    test('STRONG_BUY → long_call', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(signal: SignalType.strongBuy, optionsEdge: null),
      );
      expect(p.strategyId, 'long_call');
    });

    test('SELL → long_put', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(signal: SignalType.sell, optionsEdge: null),
      );
      expect(p.strategyId, 'long_put');
    });

    test('STRONG_SELL → long_put', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(signal: SignalType.strongSell, optionsEdge: null),
      );
      expect(p.strategyId, 'long_put');
    });

    test('NEUTRAL → csp', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(signal: SignalType.neutral, optionsEdge: null),
      );
      expect(p.strategyId, 'csp');
    });

    test('empty options_edge string falls back to signal direction', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(signal: SignalType.buy, optionsEdge: ''),
      );
      expect(p.strategyId, 'long_call');
    });
  });

  // ── Price extraction ──────────────────────────────────────────────────────
  group('Price extraction from entry_zone', () {
    test('dollar range — extracts first number', () {
      final p = SignalPlannerPreset.fromSignal(_signal(entryZone: '\$148-152'));
      expect(p.inputs.underlyingPrice, 148.0);
    });

    test('plain decimal', () {
      final p = SignalPlannerPreset.fromSignal(_signal(entryZone: '147.50'));
      expect(p.inputs.underlyingPrice, 147.50);
    });

    test('near prefix', () {
      final p = SignalPlannerPreset.fromSignal(_signal(entryZone: 'near 150'));
      expect(p.inputs.underlyingPrice, 150.0);
    });

    test('freeform text with embedded price', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(entryZone: 'Break above \$155 with volume'),
      );
      expect(p.inputs.underlyingPrice, 155.0);
    });

    test('unparseable entry_zone → null price', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(entryZone: 'on a pullback to support'),
      );
      expect(p.inputs.underlyingPrice, isNull);
    });
  });

  // ── Strike mapping for put strategies ────────────────────────────────────
  group('Strike extraction from stop for put-selling strategies', () {
    test('CSP: stop → strike', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'Sell CSP', stop: '\$140'),
      );
      expect(p.strategyId, 'csp');
      expect(p.inputs.strike, 140.0);
    });

    test('credit_spread: stop → strike', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(optionsEdge: 'credit spread below support', stop: '\$135.50'),
      );
      expect(p.strategyId, 'credit_spread');
      expect(p.inputs.strike, 135.5);
    });

    test('long_call: stop does NOT map to strike', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(signal: SignalType.buy, optionsEdge: null, stop: '\$140'),
      );
      expect(p.strategyId, 'long_call');
      expect(p.inputs.strike, isNull);
    });

    test('long_put: stop → strike', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(
          signal: SignalType.sell,
          optionsEdge: 'Long put hedge, 30 delta',
          stop: '\$162',
        ),
      );
      expect(p.strategyId, 'long_put');
      expect(p.inputs.strike, 162.0);
    });
  });

  // ── Expiry estimation ─────────────────────────────────────────────────────
  group('Expiry estimation from timeframe', () {
    final now = DateTime.now();

    test('DAYS timeframe → ~5 days out', () {
      final p = SignalPlannerPreset.fromSignal(_signal(timeframe: '1-5 DAYS'));
      final diff = p.inputs.expiration!.difference(now).inDays;
      expect(diff, inInclusiveRange(4, 6));
    });

    test('WEEKS timeframe → ~21 days out', () {
      final p = SignalPlannerPreset.fromSignal(_signal(timeframe: '1-4 WEEKS'));
      final diff = p.inputs.expiration!.difference(now).inDays;
      expect(diff, inInclusiveRange(20, 22));
    });

    test('MONTHS timeframe → ~45 days out', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(timeframe: '1-3 MONTHS'),
      );
      final diff = p.inputs.expiration!.difference(now).inDays;
      expect(diff, inInclusiveRange(44, 46));
    });

    test('unknown timeframe → null expiry', () {
      final p = SignalPlannerPreset.fromSignal(_signal(timeframe: 'INTRADAY'));
      expect(p.inputs.expiration, isNull);
    });
  });

  // ── Ticker and summary ────────────────────────────────────────────────────
  group('Ticker and signal summary', () {
    test('ticker is passed through correctly', () {
      final p = SignalPlannerPreset.fromSignal(_signal(ticker: 'NVDA'));
      expect(p.ticker, 'NVDA');
    });

    test('signalSummary includes signal label and confidence', () {
      final p = SignalPlannerPreset.fromSignal(
        _signal(signal: SignalType.strongBuy, confidence: 92),
      );
      expect(p.signalSummary, contains('STRONG BUY'));
      expect(p.signalSummary, contains('92%'));
    });
  });
}
