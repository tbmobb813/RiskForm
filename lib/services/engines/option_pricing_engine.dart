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
    // Use an Abramowitz-Stegun based erf approximation for better accuracy:
    // Φ(x) = 0.5 * (1 + erf(x / sqrt(2)))
    double erfApprox(double z) {
      final sign = z < 0 ? -1.0 : 1.0;
      final a1 = 0.254829592;
      final a2 = -0.284496736;
      final a3 = 1.421413741;
      final a4 = -1.453152027;
      final a5 = 1.061405429;
      final p = 0.3275911;

      final absZ = z.abs();
      final t = 1.0 / (1.0 + p * absZ);
      final expTerm = exp(-absZ * absZ);
      final y = 1.0 - (((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t) * expTerm;
      return sign * y;
    }

    return 0.5 * (1.0 + erfApprox(x / sqrt2));
  }
}
