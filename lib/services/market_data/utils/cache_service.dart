/// Simple in-memory LRU cache for market data
class CacheService {
  final Duration defaultTtl;
  final int maxSize;
  final Map<String, _CacheEntry> _cache = {};
  final List<String> _accessOrder = [];

  CacheService({
    this.defaultTtl = const Duration(seconds: 5),
    this.maxSize = 100,
  });

  /// Get a cached value
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) return null;

    // Check if expired
    if (entry.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return null;
    }

    // Update access order (move to end = most recently used)
    _accessOrder.remove(key);
    _accessOrder.add(key);

    return entry.value as T?;
  }

  /// Set a cached value
  void set<T>(String key, T value, {Duration? ttl}) {
    // Evict oldest if at capacity
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      final oldest = _accessOrder.first;
      _cache.remove(oldest);
      _accessOrder.remove(oldest);
    }

    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );

    // Update access order
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Check if a key exists and is not expired
  bool has(String key) {
    return get(key) != null;
  }

  /// Clear all cached values
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Clear expired entries
  void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.expiresAt.isBefore(now))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// Get cache statistics
  CacheStats get stats {
    clearExpired();
    return CacheStats(
      size: _cache.length,
      capacity: maxSize,
      hitRate: 0.0, // Would need to track hits/misses
    );
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CacheStats {
  final int size;
  final int capacity;
  final double hitRate;

  CacheStats({
    required this.size,
    required this.capacity,
    required this.hitRate,
  });

  double get usagePercent => (size / capacity) * 100;
}
