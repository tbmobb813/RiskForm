/// Token bucket rate limiter
///
/// Allows bursts up to maxCallsPerMinute, then throttles
class RateLimiter {
  final int maxCallsPerMinute;
  final List<DateTime> _callTimestamps = [];

  RateLimiter({required this.maxCallsPerMinute});

  /// Acquire permission to make an API call
  ///
  /// Waits if rate limit would be exceeded
  Future<void> acquire() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // Remove timestamps older than 1 minute
    _callTimestamps.removeWhere((timestamp) => timestamp.isBefore(oneMinuteAgo));

    // If at limit, wait until oldest call is > 1 minute old
    if (_callTimestamps.length >= maxCallsPerMinute) {
      final oldestCall = _callTimestamps.first;
      final waitTime = oldestCall.add(const Duration(minutes: 1)).difference(now);

      if (waitTime.inMilliseconds > 0) {
        await Future.delayed(waitTime);
        return acquire(); // Recursive call after waiting
      }
    }

    // Record this call
    _callTimestamps.add(now);
  }

  /// Check if we can make a call without waiting
  bool canAcquire() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    _callTimestamps.removeWhere((timestamp) => timestamp.isBefore(oneMinuteAgo));

    return _callTimestamps.length < maxCallsPerMinute;
  }

  /// Get number of remaining calls in current window
  int get remainingCalls {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    _callTimestamps.removeWhere((timestamp) => timestamp.isBefore(oneMinuteAgo));

    return maxCallsPerMinute - _callTimestamps.length;
  }

  /// Reset the rate limiter
  void reset() {
    _callTimestamps.clear();
  }
}
