import 'dart:math';

class OptionPricingEngine {
  // risk-free rate (annualized, decimal)
  final double riskFreeRate;

  OptionPricingEngine({this.riskFreeRate = 0.02});

  double priceEuropeanPut({
    required double spot,
    required double strike,
    required double volatility,
    required double timeToExpiryYears,
  }) {
    if (timeToExpiryYears <= 0 || volatility <= 0) {
      return max(strike - spot, 0);
    }

    final d1 = (log(spot / strike) +
            (riskFreeRate + 0.5 * pow(volatility, 2)) * timeToExpiryYears) /
        (volatility * sqrt(timeToExpiryYears));
    final d2 = d1 - volatility * sqrt(timeToExpiryYears);

    final nd1 = _normCdf(-d1);
    final nd2 = _normCdf(-d2);

    return strike * exp(-riskFreeRate * timeToExpiryYears) * nd2 - spot * nd1;
  }

  double priceEuropeanCall({
    required double spot,
    required double strike,
    required double volatility,
    required double timeToExpiryYears,
  }) {
    if (timeToExpiryYears <= 0 || volatility <= 0) {
      return max(spot - strike, 0);
    }

    final d1 = (log(spot / strike) +
            (riskFreeRate + 0.5 * pow(volatility, 2)) * timeToExpiryYears) /
        (volatility * sqrt(timeToExpiryYears));
    final d2 = d1 - volatility * sqrt(timeToExpiryYears);

    final nd1 = _normCdf(d1);
    final nd2 = _normCdf(d2);

    return spot * nd1 - strike * exp(-riskFreeRate * timeToExpiryYears) * nd2;
  }

  double _normCdf(double x) {
    // Abramowitz-Stegun approximation (valid for x >= 0)
    // For negative x, we use the symmetry property: Φ(-x) = 1 - Φ(x)
    const p = 0.2316419;
    const b1 = 0.319381530;
    const b2 = -0.356563782;
    const b3 = 1.781477937;
    const b4 = -1.821255978;
    const b5 = 1.330274429;

    // Evaluate polynomial at |x| since approximation requires x >= 0
    final t = 1.0 / (1.0 + p * x.abs());
    final poly = b1 * t +
        b2 * pow(t, 2) +
        b3 * pow(t, 3) +
        b4 * pow(t, 4) +
        b5 * pow(t, 5);
    final pdf = (1 / sqrt(2 * pi)) * exp(-0.5 * x * x);
    final cdf = 1 - pdf * poly;

    // Apply symmetry property for negative x: Φ(-x) = 1 - Φ(x)
    return x >= 0 ? cdf : 1 - cdf;
  }
}
