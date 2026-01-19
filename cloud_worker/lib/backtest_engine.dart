import 'dart:math';

/// Simplified pure-Dart backtest engine for Cloud Run.
///
/// This mirrors the core wheel strategy logic from the main Flutter app
/// but without Flutter dependencies. For full feature parity, consider
/// extracting shared code into a common Dart package.
class CloudBacktestEngine {
  static const String engineVersion = '1.0.0-cloud';

  Map<String, dynamic> run(Map<String, dynamic> config) {
    final startingCapital = (config['startingCapital'] as num).toDouble();
    final pricePath = List<double>.from(
      (config['pricePath'] as List).map((e) => (e as num).toDouble()),
    );
    // Symbol available for future use (e.g., early assignment heuristics)
    // final symbol = config['symbol'] as String;

    if (pricePath.isEmpty) {
      throw Exception('Backtest requires a non-empty price path.');
    }

    // Simulation state
    double capital = startingCapital;
    int shares = 0;
    double costBasis = 0.0;
    String state = 'idle';

    // Option tracking
    double? cspStrike;
    int cspDte = 0;
    double? ccStrike;
    int ccDte = 0;

    final equityCurve = <double>[];
    final notes = <String>[];
    final cycles = <Map<String, dynamic>>[];

    int cycleCount = 0;
    double cycleStartEquity = startingCapital;
    int cycleDuration = 0;
    bool cycleHadAssignment = false;

    for (final price in pricePath) {
      // Decrement DTE
      if (cspStrike != null) cspDte -= 1;
      if (ccStrike != null) ccDte -= 1;

      // State machine
      switch (state) {
        case 'idle':
          // Sell CSP at ATM
          final strike = price;
          final premium = _blackScholesPut(price, strike, 0.25, 30 / 365.0) * 100;
          capital += premium;
          cspStrike = strike;
          cspDte = 30;
          state = 'cspOpen';
          notes.add('Sold CSP @ ${strike.toStringAsFixed(2)}, premium ${premium.toStringAsFixed(2)}');
          break;

        case 'cspOpen':
          if (cspStrike == null) {
            state = 'idle';
            break;
          }

          final isITM = price < cspStrike;

          if (cspDte <= 0) {
            if (isITM) {
              // Assignment
              shares = 100;
              costBasis = cspStrike;
              capital -= cspStrike * 100;
              notes.add('CSP expired ITM, assigned @ ${cspStrike.toStringAsFixed(2)}');
              cycleHadAssignment = true;
              state = 'assigned';
            } else {
              notes.add('CSP expired OTM');
              state = 'idle';
            }
            cspStrike = null;
            cspDte = 0;
          }
          break;

        case 'assigned':
          notes.add('Shares confirmed at cost basis ${costBasis.toStringAsFixed(2)}');
          state = 'sharesOwned';
          break;

        case 'sharesOwned':
          // Sell covered call 2% OTM
          final strike = price * 1.02;
          final premium = _blackScholesCall(price, strike, 0.25, 30 / 365.0) * 100;
          capital += premium;
          ccStrike = strike;
          ccDte = 30;
          state = 'ccOpen';
          notes.add('Sold CC @ ${strike.toStringAsFixed(2)}, premium ${premium.toStringAsFixed(2)}');
          break;

        case 'ccOpen':
          if (ccStrike == null) {
            state = 'sharesOwned';
            break;
          }

          final isITM = price > ccStrike;

          if (ccDte <= 0) {
            if (isITM) {
              // Called away
              final proceeds = ccStrike * 100;
              capital += proceeds;
              shares = 0;

              // Complete cycle
              final endEquity = capital + shares * price;
              cycles.add({
                'index': cycleCount,
                'startEquity': cycleStartEquity,
                'endEquity': endEquity,
                'durationDays': cycleDuration,
                'hadAssignment': cycleHadAssignment,
                'outcome': 'calledAway',
              });

              cycleCount++;
              cycleStartEquity = endEquity;
              cycleDuration = 0;
              cycleHadAssignment = false;

              notes.add('CC expired ITM, called away @ ${ccStrike.toStringAsFixed(2)}');
              state = 'idle';
            } else {
              notes.add('CC expired OTM, keeping shares');
              state = 'sharesOwned';
            }
            ccStrike = null;
            ccDte = 0;
          }
          break;
      }

      final equity = capital + shares * price;
      equityCurve.add(equity);
      cycleDuration++;
    }

    // Calculate metrics
    final totalReturn = equityCurve.isNotEmpty
        ? (equityCurve.last - startingCapital) / startingCapital
        : 0.0;

    double maxDrawdown = 0.0;
    double peak = startingCapital;
    for (final equity in equityCurve) {
      if (equity > peak) peak = equity;
      final drawdown = (peak - equity) / peak;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }

    final avgCycleReturn = cycles.isNotEmpty
        ? cycles.map((c) => ((c['endEquity'] as double) - (c['startEquity'] as double)) / (c['startEquity'] as double)).reduce((a, b) => a + b) / cycles.length
        : 0.0;

    final avgCycleDuration = cycles.isNotEmpty
        ? cycles.map((c) => c['durationDays'] as int).reduce((a, b) => a + b) / cycles.length
        : 0.0;

    final assignmentRate = cycles.isNotEmpty
        ? cycles.where((c) => c['hadAssignment'] == true).length / cycles.length
        : 0.0;

    return {
      'configUsed': config,
      'equityCurve': equityCurve,
      'maxDrawdown': -maxDrawdown,
      'totalReturn': totalReturn,
      'cyclesCompleted': cycleCount,
      'notes': notes,
      'cycles': cycles,
      'avgCycleReturn': avgCycleReturn,
      'avgCycleDurationDays': avgCycleDuration,
      'assignmentRate': assignmentRate,
      'uptrendAvgCycleReturn': avgCycleReturn,
      'downtrendAvgCycleReturn': avgCycleReturn,
      'sidewaysAvgCycleReturn': avgCycleReturn,
      'uptrendAssignmentRate': assignmentRate,
      'downtrendAssignmentRate': assignmentRate,
      'sidewaysAssignmentRate': assignmentRate,
      'engineVersion': engineVersion,
      'regimeSegments': <Map<String, dynamic>>[],
    };
  }

  // Black-Scholes pricing (simplified, no dividends, r=0)
  double _blackScholesCall(double S, double K, double sigma, double T) {
    if (T <= 0) return max(0, S - K);
    final d1 = (log(S / K) + 0.5 * sigma * sigma * T) / (sigma * sqrt(T));
    final d2 = d1 - sigma * sqrt(T);
    return S * _cdf(d1) - K * _cdf(d2);
  }

  double _blackScholesPut(double S, double K, double sigma, double T) {
    if (T <= 0) return max(0, K - S);
    final d1 = (log(S / K) + 0.5 * sigma * sigma * T) / (sigma * sqrt(T));
    final d2 = d1 - sigma * sqrt(T);
    return K * _cdf(-d2) - S * _cdf(-d1);
  }

  // Standard normal CDF approximation
  double _cdf(double x) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs() / sqrt(2);

    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x);

    return 0.5 * (1.0 + sign * y);
  }
}
