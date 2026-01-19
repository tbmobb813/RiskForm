import 'dart:math';

/// Simplified pure-Dart backtest engine for use by both app and workers.
class CloudBacktestEngine {
  static const String engineVersion = '1.0.0-cloud';

  Map<String, dynamic> run(Map<String, dynamic> config) {
    final startingCapital = (config['startingCapital'] as num).toDouble();
    final pricePath = List<double>.from(
      (config['pricePath'] as List).map((e) => (e as num).toDouble()),
    );

    if (pricePath.isEmpty) {
      throw Exception('Backtest requires a non-empty price path.');
    }

    double capital = startingCapital;
    int shares = 0;
    double costBasis = 0.0;
    String state = 'idle';

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
    bool resetCycleThisIteration = false;

    for (final price in pricePath) {
      if (cspStrike != null) cspDte -= 1;
      if (ccStrike != null) ccDte -= 1;

      switch (state) {
        case 'idle':
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
              final proceeds = ccStrike * 100;
              capital += proceeds;
              shares = 0;

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
              resetCycleThisIteration = true;
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
      if (resetCycleThisIteration) {
        resetCycleThisIteration = false;
      } else {
        cycleDuration++;
      }
    }

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

  double _blackScholesCall(double S, double K, double sigma, double T) {
    if (S <= 0 || K <= 0) {
      throw StateError('Invalid inputs to Black-Scholes call: S=$S K=$K');
    }
    if (T <= 0 || sigma <= 0) return max(0, S - K);

    final denom = sigma * sqrt(T);
    if (denom == 0) return max(0, S - K);

    final d1 = (log(S / K) + 0.5 * sigma * sigma * T) / denom;
    final d2 = d1 - denom;
    final price = S * _cdf(d1) - K * _cdf(d2);
    if (price.isNaN || price.isInfinite || price < 0) {
      throw StateError('Invalid Black-Scholes call price computed: $price (S=$S K=$K sigma=$sigma T=$T)');
    }
    return price;
  }

  double _blackScholesPut(double S, double K, double sigma, double T) {
    if (S <= 0 || K <= 0) {
      throw StateError('Invalid inputs to Black-Scholes put: S=$S K=$K');
    }
    if (T <= 0 || sigma <= 0) return max(0, K - S);

    final denom = sigma * sqrt(T);
    if (denom == 0) return max(0, K - S);

    final d1 = (log(S / K) + 0.5 * sigma * sigma * T) / denom;
    final d2 = d1 - denom;
    final price = K * _cdf(-d2) - S * _cdf(-d1);
    if (price.isNaN || price.isInfinite || price < 0) {
      throw StateError('Invalid Black-Scholes put price computed: $price (S=$S K=$K sigma=$sigma T=$T)');
    }
    return price;
  }

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

  double priceCall(double S, double K, double sigma, double T) => _blackScholesCall(S, K, sigma, T);
  double pricePut(double S, double K, double sigma, double T) => _blackScholesPut(S, K, sigma, T);
}
