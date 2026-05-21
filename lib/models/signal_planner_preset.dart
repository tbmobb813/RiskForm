import 'signal_model.dart';
import 'trade_inputs.dart';

/// Carries signal-derived data into the Planner so fields are pre-filled.
class SignalPlannerPreset {
  final String ticker;
  final String strategyId;
  final String strategyName;
  final String strategyDescription;
  final TradeInputs inputs;

  /// Short human-readable summary shown as a banner in the planner.
  final String signalSummary;

  const SignalPlannerPreset({
    required this.ticker,
    required this.strategyId,
    required this.strategyName,
    required this.strategyDescription,
    required this.inputs,
    required this.signalSummary,
  });

  factory SignalPlannerPreset.fromSignal(SignalModel signal) {
    final (id, name, desc) = _inferStrategy(signal);
    final price = _extractFirstPrice(signal.entryZone);
    final stop = _extractFirstPrice(signal.stop);
    final expiry = _estimateExpiry(signal.timeframe);

    // For put-selling strategies the stop level maps naturally to the strike.
    final strike = switch (id) {
      'csp' || 'credit_spread' || 'long_put' => stop,
      _ => null,
    };

    return SignalPlannerPreset(
      ticker: signal.ticker,
      strategyId: id,
      strategyName: name,
      strategyDescription: desc,
      inputs: TradeInputs(
        underlyingPrice: price,
        strike: strike,
        expiration: expiry,
      ),
      signalSummary:
          '${_signalLabel(signal.signal)} · ${signal.confidence}% confidence',
    );
  }

  // ── Strategy inference ────────────────────────────────────────────────────

  static (String, String, String) _inferStrategy(SignalModel signal) {
    final edge = (signal.optionsEdge ?? '').toLowerCase();

    // Explicit keyword matches first
    if (_contains(edge, ['pmcc', 'poor man'])) {
      return (
        'long_call',
        'PMCC',
        'Buy a deep ITM LEAPS call and sell short-term covered calls against it.',
      );
    }
    if (_contains(edge, ['covered call', ' cc '])) {
      return (
        'cc',
        'Covered Call',
        'Sell a call against shares you own to generate income.',
      );
    }
    if (_contains(edge, ['cash-secured put', 'csp', 'cash secured'])) {
      return (
        'csp',
        'Cash-Secured Put',
        'Sell a put and reserve cash for potential assignment.',
      );
    }
    if (_contains(edge, ['debit spread', 'bull call', 'bear put'])) {
      return (
        'debit_spread',
        'Debit Spread',
        'Buy one option and sell another to reduce cost basis.',
      );
    }
    if (_contains(edge, ['credit spread', 'bull put', 'bear call'])) {
      return (
        'credit_spread',
        'Credit Spread',
        'Sell a spread to collect a net credit with defined risk.',
      );
    }
    if (_contains(edge, ['long call', 'buy call'])) {
      return (
        'long_call',
        'Long Call',
        'Buy a call option for directional upside exposure.',
      );
    }
    if (_contains(edge, ['long put', 'buy put'])) {
      return (
        'long_put',
        'Long Put',
        'Buy a put option for directional downside exposure.',
      );
    }
    if (_contains(edge, ['wheel'])) {
      return (
        'csp',
        'Wheel (CSP leg)',
        'Start the Wheel by selling a cash-secured put.',
      );
    }
    if (_contains(edge, ['iron condor'])) {
      return (
        'credit_spread',
        'Iron Condor',
        'Sell both a call spread and a put spread for neutral income.',
      );
    }

    // Fall back to signal direction
    return switch (signal.signal) {
      SignalType.strongBuy || SignalType.buy => (
        'long_call',
        'Long Call',
        'Directional bullish play aligned with the signal.',
      ),
      SignalType.sell => (
        'long_put',
        'Long Put',
        'Directional bearish play aligned with the signal.',
      ),
      SignalType.strongSell => (
        'long_put',
        'Long Put',
        'Strong bearish signal — long put for downside exposure.',
      ),
      SignalType.neutral => (
        'csp',
        'Cash-Secured Put',
        'Neutral-to-bullish premium selling on a range-bound ticker.',
      ),
    };
  }

  static bool _contains(String text, List<String> terms) =>
      terms.any(text.contains);

  // ── Price extraction ──────────────────────────────────────────────────────
  /// Extracts the first dollar amount from freeform text like "$145-150" or "near 148.5".
  static double? _extractFirstPrice(String text) {
    final match = RegExp(r'\$?([\d]+(?:\.\d+)?)').firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  // ── Expiry estimation ─────────────────────────────────────────────────────
  static DateTime? _estimateExpiry(String timeframe) {
    final t = timeframe.toUpperCase();
    final now = DateTime.now();
    if (t.contains('DAYS')) return now.add(const Duration(days: 5));
    if (t.contains('WEEK')) return now.add(const Duration(days: 21));
    if (t.contains('MONTH')) return now.add(const Duration(days: 45));
    return null;
  }

  // ── Signal label ──────────────────────────────────────────────────────────
  static String _signalLabel(SignalType t) => switch (t) {
    SignalType.strongBuy => 'STRONG BUY',
    SignalType.buy => 'BUY',
    SignalType.neutral => 'NEUTRAL',
    SignalType.sell => 'SELL',
    SignalType.strongSell => 'STRONG SELL',
  };
}
