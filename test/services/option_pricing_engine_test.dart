import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/engines/option_pricing_engine.dart';
import 'dart:math';

void main() {
  group('OptionPricingEngine - European Call Options', () {
    final engine = OptionPricingEngine(riskFreeRate: 0.05);

    test('ITM call option (spot > strike)', () {
      // In-the-money call: spot price above strike
      final price = engine.priceEuropeanCall(
        spot: 110.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Expected value calculated using Black-Scholes formula
      // For S=110, K=100, r=0.05, σ=0.20, T=1.0
      // Call price ≈ 16.73
      expect(price, greaterThan(15.0));
      expect(price, lessThan(18.0));
    });

    test('ATM call option (spot ≈ strike)', () {
      // At-the-money call: spot price equals strike
      final price = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Expected value: Call price ≈ 10.45
      expect(price, greaterThan(9.0));
      expect(price, lessThan(12.0));
    });

    test('OTM call option (spot < strike)', () {
      // Out-of-the-money call: spot price below strike
      final price = engine.priceEuropeanCall(
        spot: 90.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Expected value: Call price ≈ 5.63
      expect(price, greaterThan(4.0));
      expect(price, lessThan(7.0));
    });

    test('Call option with benchmark values', () {
      // Test against known Black-Scholes benchmark
      // S=100, K=100, r=0.05, σ=0.25, T=0.5
      final price = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.25,
        timeToExpiryYears: 0.5,
      );

      // Known Black-Scholes value ≈ 8.92
      expect(price, closeTo(8.92, 0.5));
    });

    test('Call option respects put-call parity', () {
      // Put-Call Parity: C - P = S - K*e^(-rT)
      const spot = 100.0;
      const strike = 100.0;
      const volatility = 0.20;
      const timeToExpiryYears = 1.0;
      const riskFreeRate = 0.05;

      final callPrice = engine.priceEuropeanCall(
        spot: spot,
        strike: strike,
        volatility: volatility,
        timeToExpiryYears: timeToExpiryYears,
      );

      final putPrice = engine.priceEuropeanPut(
        spot: spot,
        strike: strike,
        volatility: volatility,
        timeToExpiryYears: timeToExpiryYears,
      );

      final parityLeft = callPrice - putPrice;
      final parityRight = spot - strike * exp(-riskFreeRate * timeToExpiryYears);

      expect(parityLeft, closeTo(parityRight, 0.01));
    });
  });

  group('OptionPricingEngine - European Put Options', () {
    final engine = OptionPricingEngine(riskFreeRate: 0.05);

    test('ITM put option (spot < strike)', () {
      // In-the-money put: spot price below strike
      final price = engine.priceEuropeanPut(
        spot: 90.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Expected value calculated using Black-Scholes formula
      // For S=90, K=100, r=0.05, σ=0.20, T=1.0
      // Put price ≈ 10.75
      expect(price, greaterThan(9.0));
      expect(price, lessThan(12.0));
    });

    test('ATM put option (spot ≈ strike)', () {
      // At-the-money put: spot price equals strike
      final price = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Expected value: Put price ≈ 5.57
      expect(price, greaterThan(4.5));
      expect(price, lessThan(6.5));
    });

    test('OTM put option (spot > strike)', () {
      // Out-of-the-money put: spot price above strike
      final price = engine.priceEuropeanPut(
        spot: 110.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Expected value: Put price ≈ 1.85
      expect(price, greaterThan(1.0));
      expect(price, lessThan(3.0));
    });

    test('Put option with benchmark values', () {
      // Test against known Black-Scholes benchmark
      // S=100, K=105, r=0.05, σ=0.25, T=0.5
      final price = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 105.0,
        volatility: 0.25,
        timeToExpiryYears: 0.5,
      );

      // Known Black-Scholes value ≈ 11.35
      expect(price, closeTo(11.35, 0.5));
    });
  });

  group('OptionPricingEngine - Edge Cases', () {
    final engine = OptionPricingEngine(riskFreeRate: 0.05);

    test('Call option with zero time to expiry', () {
      // At expiry, call value = max(S - K, 0)
      final priceITM = engine.priceEuropeanCall(
        spot: 110.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 0.0,
      );
      expect(priceITM, closeTo(10.0, 0.01)); // 110 - 100

      final priceOTM = engine.priceEuropeanCall(
        spot: 90.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 0.0,
      );
      expect(priceOTM, closeTo(0.0, 0.01));
    });

    test('Put option with zero time to expiry', () {
      // At expiry, put value = max(K - S, 0)
      final priceITM = engine.priceEuropeanPut(
        spot: 90.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 0.0,
      );
      expect(priceITM, closeTo(10.0, 0.01)); // 100 - 90

      final priceOTM = engine.priceEuropeanPut(
        spot: 110.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 0.0,
      );
      expect(priceOTM, closeTo(0.0, 0.01));
    });

    test('Call option with zero volatility', () {
      // With zero volatility, option value is intrinsic value discounted
      final priceITM = engine.priceEuropeanCall(
        spot: 110.0,
        strike: 100.0,
        volatility: 0.0,
        timeToExpiryYears: 1.0,
      );
      // Intrinsic value = max(110 - 100, 0) = 10
      expect(priceITM, closeTo(10.0, 0.01));

      final priceOTM = engine.priceEuropeanCall(
        spot: 90.0,
        strike: 100.0,
        volatility: 0.0,
        timeToExpiryYears: 1.0,
      );
      expect(priceOTM, closeTo(0.0, 0.01));
    });

    test('Put option with zero volatility', () {
      // With zero volatility, option value is intrinsic value discounted
      final priceITM = engine.priceEuropeanPut(
        spot: 90.0,
        strike: 100.0,
        volatility: 0.0,
        timeToExpiryYears: 1.0,
      );
      // Intrinsic value = max(100 - 90, 0) = 10
      expect(priceITM, closeTo(10.0, 0.01));

      final priceOTM = engine.priceEuropeanPut(
        spot: 110.0,
        strike: 100.0,
        volatility: 0.0,
        timeToExpiryYears: 1.0,
      );
      expect(priceOTM, closeTo(0.0, 0.01));
    });

    test('Call option with very high volatility', () {
      // High volatility increases option value
      final price = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 1.0, // 100% volatility
        timeToExpiryYears: 1.0,
      );

      // Should be significantly higher than low volatility case
      expect(price, greaterThan(30.0));
    });

    test('Put option with very high volatility', () {
      // High volatility increases option value
      final price = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 1.0, // 100% volatility
        timeToExpiryYears: 1.0,
      );

      // Should be significantly higher than low volatility case
      expect(price, greaterThan(25.0));
    });

    test('Call option with negative time to expiry throws no error', () {
      // Edge case: negative time should be handled gracefully
      final price = engine.priceEuropeanCall(
        spot: 110.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: -0.1,
      );
      
      // Should return intrinsic value
      expect(price, closeTo(10.0, 0.01));
    });

    test('Options with very small spot price', () {
      // Test with penny stock
      final callPrice = engine.priceEuropeanCall(
        spot: 1.0,
        strike: 1.0,
        volatility: 0.50,
        timeToExpiryYears: 0.25,
      );

      final putPrice = engine.priceEuropeanPut(
        spot: 1.0,
        strike: 1.0,
        volatility: 0.50,
        timeToExpiryYears: 0.25,
      );

      // Options should still have positive value
      expect(callPrice, greaterThan(0));
      expect(putPrice, greaterThan(0));
    });

    test('Options with very large spot price', () {
      // Test with high-priced stock
      final callPrice = engine.priceEuropeanCall(
        spot: 10000.0,
        strike: 10000.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      final putPrice = engine.priceEuropeanPut(
        spot: 10000.0,
        strike: 10000.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Options should still have reasonable values relative to spot
      expect(callPrice, greaterThan(900.0));
      expect(callPrice, lessThan(1200.0));
      expect(putPrice, greaterThan(400.0));
      expect(putPrice, lessThan(700.0));
    });
  });

  group('OptionPricingEngine - Different Risk-Free Rates', () {
    test('Call option with different risk-free rates', () {
      final lowRateEngine = OptionPricingEngine(riskFreeRate: 0.01);
      final highRateEngine = OptionPricingEngine(riskFreeRate: 0.10);

      final lowRatePrice = lowRateEngine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      final highRatePrice = highRateEngine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Higher risk-free rate should increase call price
      expect(highRatePrice, greaterThan(lowRatePrice));
    });

    test('Put option with different risk-free rates', () {
      final lowRateEngine = OptionPricingEngine(riskFreeRate: 0.01);
      final highRateEngine = OptionPricingEngine(riskFreeRate: 0.10);

      final lowRatePrice = lowRateEngine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      final highRatePrice = highRateEngine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Higher risk-free rate should decrease put price
      expect(lowRatePrice, greaterThan(highRatePrice));
    });

    test('Zero risk-free rate', () {
      final engine = OptionPricingEngine(riskFreeRate: 0.0);

      final callPrice = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      final putPrice = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      // Should still produce valid prices
      expect(callPrice, greaterThan(0));
      expect(putPrice, greaterThan(0));
    });
  });

  group('OptionPricingEngine - Time Decay', () {
    final engine = OptionPricingEngine(riskFreeRate: 0.05);

    test('Call option loses value as time to expiry decreases', () {
      final price1Year = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      final price6Months = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 0.5,
      );

      final price1Month = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0 / 12.0,
      );

      // Time value should decrease as expiry approaches
      expect(price1Year, greaterThan(price6Months));
      expect(price6Months, greaterThan(price1Month));
    });

    test('Put option loses value as time to expiry decreases', () {
      final price1Year = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0,
      );

      final price6Months = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 0.5,
      );

      final price1Month = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.20,
        timeToExpiryYears: 1.0 / 12.0,
      );

      // Time value should decrease as expiry approaches
      expect(price1Year, greaterThan(price6Months));
      expect(price6Months, greaterThan(price1Month));
    });
  });

  group('OptionPricingEngine - Volatility Impact', () {
    final engine = OptionPricingEngine(riskFreeRate: 0.05);

    test('Call option increases with volatility', () {
      final lowVolPrice = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.10,
        timeToExpiryYears: 1.0,
      );

      final medVolPrice = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.30,
        timeToExpiryYears: 1.0,
      );

      final highVolPrice = engine.priceEuropeanCall(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.50,
        timeToExpiryYears: 1.0,
      );

      // Higher volatility increases option value
      expect(medVolPrice, greaterThan(lowVolPrice));
      expect(highVolPrice, greaterThan(medVolPrice));
    });

    test('Put option increases with volatility', () {
      final lowVolPrice = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.10,
        timeToExpiryYears: 1.0,
      );

      final medVolPrice = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.30,
        timeToExpiryYears: 1.0,
      );

      final highVolPrice = engine.priceEuropeanPut(
        spot: 100.0,
        strike: 100.0,
        volatility: 0.50,
        timeToExpiryYears: 1.0,
      );

      // Higher volatility increases option value
      expect(medVolPrice, greaterThan(lowVolPrice));
      expect(highVolPrice, greaterThan(medVolPrice));
    });
  });
}
