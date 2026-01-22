import 'dart:math';

final double _sqrt2pi = sqrt(2 * pi);

/// LRU cache for option pricing calculations.
class _PricingCache {
  final int maxSize;
  final Map<String, double> _cache = {};
  final List<String> _accessOrder = [];

  _PricingCache({this.maxSize = 10000});

  double? get(String key) {
    final value = _cache[key];
    if (value != null) {
      // Move to end (most recently used)
      _accessOrder.remove(key);
      _accessOrder.add(key);
    }
    return value;
  }

  void put(String key, double value) {
    if (_cache.containsKey(key)) {
      _cache[key] = value;
      _accessOrder.remove(key);
      _accessOrder.add(key);
    } else {
      if (_cache.length >= maxSize) {
        // Remove least recently used
        final lruKey = _accessOrder.removeAt(0);
        _cache.remove(lruKey);
      }
      _cache[key] = value;
      _accessOrder.add(key);
    }
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  int get size => _cache.length;
}

class OptionPricingEngine {
  // risk-free rate (annualized, decimal)
  final double riskFreeRate;

  /// Enable/disable caching (useful for testing)
  final bool enableCache;

  /// Cache for put prices
  final _PricingCache _putCache;

  /// Cache for call prices
  final _PricingCache _callCache;

  OptionPricingEngine({
    this.riskFreeRate = 0.02,
    this.enableCache = true,
    int cacheSize = 10000,
  })  : _putCache = _PricingCache(maxSize: cacheSize),
        _callCache = _PricingCache(maxSize: cacheSize);

  /// Generates a cache key from pricing inputs.
  /// Rounds values to reduce cache misses from floating point variance.
  String _cacheKey(double spot, double strike, double volatility, double time) {
    // Round to 4 decimal places for reasonable precision
    final s = spot.toStringAsFixed(4);
    final k = strike.toStringAsFixed(4);
    final v = volatility.toStringAsFixed(4);
    final t = time.toStringAsFixed(6);
    return '$s|$k|$v|$t';
  }

  /// Clears the pricing cache.
  void clearCache() {
    _putCache.clear();
    _callCache.clear();
  }

  /// Returns cache statistics for monitoring.
  Map<String, int> get cacheStats => {
        'putCacheSize': _putCache.size,
        'callCacheSize': _callCache.size,
      };

  double priceEuropeanPut({
    required double spot,
    required double strike,
    required double volatility,
    required double timeToExpiryYears,
  }) {
    if (timeToExpiryYears <= 0 || volatility <= 0) {
      return max(strike - spot, 0);
    }

    // Check cache first
    if (enableCache) {
      final key = _cacheKey(spot, strike, volatility, timeToExpiryYears);
      final cached = _putCache.get(key);
      if (cached != null) return cached;

      final price = _computePutPrice(spot, strike, volatility, timeToExpiryYears);
      _putCache.put(key, price);
      return price;
    }

    return _computePutPrice(spot, strike, volatility, timeToExpiryYears);
  }

  double _computePutPrice(double spot, double strike, double volatility, double timeToExpiryYears) {
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

    // Check cache first
    if (enableCache) {
      final key = _cacheKey(spot, strike, volatility, timeToExpiryYears);
      final cached = _callCache.get(key);
      if (cached != null) return cached;

      final price = _computeCallPrice(spot, strike, volatility, timeToExpiryYears);
      _callCache.put(key, price);
      return price;
    }

    return _computeCallPrice(spot, strike, volatility, timeToExpiryYears);
  }

  double _computeCallPrice(double spot, double strike, double volatility, double timeToExpiryYears) {
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

  double _normPdf(double x) {
    return (1.0 / _sqrt2pi) * exp(-0.5 * x * x);
  }

  /// Black-Scholes Delta (call positive, put negative). Returns delta per
  /// single underlying (0..1 for calls, -1..0 for puts).
  double delta({
    required bool isCall,
    required double spot,
    required double strike,
    required double volatility,
    required double timeToExpiryYears,
  }) {
    if (timeToExpiryYears <= 0 || volatility <= 0) {
      if (isCall) return spot > strike ? 1.0 : 0.0;
      return spot < strike ? -1.0 : 0.0;
    }

    final d1 = (log(spot / strike) + (riskFreeRate + 0.5 * pow(volatility, 2)) * timeToExpiryYears) / (volatility * sqrt(timeToExpiryYears));
    if (isCall) return _normCdf(d1);
    return _normCdf(d1) - 1.0;
  }

  /// Black-Scholes Vega (per 1.0 volatility, e.g. 0.01 = 1%). Returns vega
  /// in price units (dollars) per underlying per 1.0 vol.
  double vega({
    required double spot,
    required double strike,
    required double volatility,
    required double timeToExpiryYears,
  }) {
    if (timeToExpiryYears <= 0 || volatility <= 0) return 0.0;
    final d1 = (log(spot / strike) + (riskFreeRate + 0.5 * pow(volatility, 2)) * timeToExpiryYears) / (volatility * sqrt(timeToExpiryYears));
    return spot * _normPdf(d1) * sqrt(timeToExpiryYears);
  }

  /// Black-Scholes Theta (per day) for call/put. Returns theta in price
  /// units (dollars) per underlying *per day*.
  double theta({
    required bool isCall,
    required double spot,
    required double strike,
    required double volatility,
    required double timeToExpiryYears,
  }) {
    if (timeToExpiryYears <= 0 || volatility <= 0) return 0.0;

    final d1 = (log(spot / strike) + (riskFreeRate + 0.5 * pow(volatility, 2)) * timeToExpiryYears) / (volatility * sqrt(timeToExpiryYears));
    final d2 = d1 - volatility * sqrt(timeToExpiryYears);

    final firstTerm = - (spot * _normPdf(d1) * volatility) / (2 * sqrt(timeToExpiryYears));
    final secondTermCall = riskFreeRate * strike * exp(-riskFreeRate * timeToExpiryYears) * _normCdf(d2);
    final secondTermPut = riskFreeRate * strike * exp(-riskFreeRate * timeToExpiryYears) * _normCdf(-d2);

    // Theta is usually annualized; convert to per-day by dividing by 365.
    final thetaAnnual = isCall ? (firstTerm - secondTermCall) : (firstTerm + secondTermPut);
    return thetaAnnual / 365.0;
  }
}
