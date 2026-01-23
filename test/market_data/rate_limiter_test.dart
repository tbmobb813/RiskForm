import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/market_data/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('allows calls within rate limit', () async {
      final limiter = RateLimiter(maxCallsPerMinute: 10);

      // Should complete immediately
      final stopwatch = Stopwatch()..start();

      await limiter.acquire();
      await limiter.acquire();
      await limiter.acquire();

      stopwatch.stop();

      // Should take less than 100ms (generous threshold)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('throttles calls exceeding rate limit', () async {
      final limiter = RateLimiter(maxCallsPerMinute: 2);

      final stopwatch = Stopwatch()..start();

      await limiter.acquire(); // Call 1 (immediate)
      await limiter.acquire(); // Call 2 (immediate)
      await limiter.acquire(); // Call 3 (should wait ~30 seconds)

      stopwatch.stop();

      // Should have waited approximately 30 seconds
      // (60 seconds / 2 calls per minute = 30 seconds per call)
      expect(stopwatch.elapsedMilliseconds, greaterThan(25000));
    }, timeout: const Timeout(Duration(seconds: 35)));

    test('refills tokens over time', () async {
      final limiter = RateLimiter(maxCallsPerMinute: 6);

      // Use all tokens
      await limiter.acquire();
      await limiter.acquire();
      await limiter.acquire();
      await limiter.acquire();
      await limiter.acquire();
      await limiter.acquire();

      // Wait for 10 seconds (should refill 1 token at 6/min rate)
      await Future.delayed(const Duration(seconds: 10));

      final stopwatch = Stopwatch()..start();
      await limiter.acquire();
      stopwatch.stop();

      // Should complete quickly since token was refilled
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('handles high burst of requests', () async {
      final limiter = RateLimiter(maxCallsPerMinute: 5);

      final stopwatch = Stopwatch()..start();

      // Make 10 requests (should take ~2 minutes at 5/min)
      for (int i = 0; i < 10; i++) {
        await limiter.acquire();
      }

      stopwatch.stop();

      // Should take at least 1 minute (conservative estimate)
      expect(stopwatch.elapsedMilliseconds, greaterThan(60000));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('different instances have independent limits', () async {
      final limiter1 = RateLimiter(maxCallsPerMinute: 2);
      final limiter2 = RateLimiter(maxCallsPerMinute: 2);

      // Exhaust limiter1
      await limiter1.acquire();
      await limiter1.acquire();

      // limiter2 should still be immediate
      final stopwatch = Stopwatch()..start();
      await limiter2.acquire();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('provides rate limit statistics', () async {
      final limiter = RateLimiter(maxCallsPerMinute: 10);

      await limiter.acquire();
      await limiter.acquire();
      await limiter.acquire();

      final stats = limiter.stats;

      expect(stats['maxCallsPerMinute'], 10);
      expect(stats['availableTokens'], lessThanOrEqualTo(10));
      expect(stats['totalAcquired'], 3);
    });

    test('resets counter correctly', () async {
      final limiter = RateLimiter(maxCallsPerMinute: 5);

      await limiter.acquire();
      await limiter.acquire();

      var stats = limiter.stats;
      expect(stats['totalAcquired'], 2);

      limiter.reset();

      stats = limiter.stats;
      expect(stats['totalAcquired'], 0);
      expect(stats['availableTokens'], 5);
    });
  });
}
