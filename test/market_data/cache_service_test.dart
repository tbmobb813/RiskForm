import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/market_data/utils/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService cache;

    setUp(() {
      cache = CacheService(
        defaultTtl: const Duration(seconds: 5),
        maxSize: 3,
      );
    });

    test('stores and retrieves value', () {
      cache.set('key1', 'value1');
      expect(cache.get<String>('key1'), 'value1');
    });

    test('returns null for non-existent key', () {
      expect(cache.get<String>('nonexistent'), null);
    });

    test('respects TTL', () async {
      cache.set('key1', 'value1', ttl: const Duration(milliseconds: 100));

      expect(cache.get<String>('key1'), 'value1');

      await Future.delayed(const Duration(milliseconds: 150));

      expect(cache.get<String>('key1'), null);
    });

    test('uses default TTL when not specified', () async {
      final cache = CacheService(
        defaultTtl: const Duration(milliseconds: 100),
        maxSize: 10,
      );

      cache.set('key1', 'value1');

      expect(cache.get<String>('key1'), 'value1');

      await Future.delayed(const Duration(milliseconds: 150));

      expect(cache.get<String>('key1'), null);
    });

    test('enforces max size (LRU eviction)', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.set('key3', 'value3');

      // All three should be present
      expect(cache.get<String>('key1'), 'value1');
      expect(cache.get<String>('key2'), 'value2');
      expect(cache.get<String>('key3'), 'value3');

      // Adding fourth should evict least recently used (key1)
      cache.set('key4', 'value4');

      expect(cache.get<String>('key1'), null);
      expect(cache.get<String>('key2'), 'value2');
      expect(cache.get<String>('key3'), 'value3');
      expect(cache.get<String>('key4'), 'value4');
    });

    test('accessing key updates LRU order', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.set('key3', 'value3');

      // Access key1 to make it most recently used
      cache.get<String>('key1');

      // Adding fourth should evict key2 (now least recently used)
      cache.set('key4', 'value4');

      expect(cache.get<String>('key1'), 'value1');
      expect(cache.get<String>('key2'), null);
      expect(cache.get<String>('key3'), 'value3');
      expect(cache.get<String>('key4'), 'value4');
    });

    test('clears all entries', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      expect(cache.get<String>('key1'), 'value1');
      expect(cache.get<String>('key2'), 'value2');

      cache.clear();

      expect(cache.get<String>('key1'), null);
      expect(cache.get<String>('key2'), null);
    });

    test('handles complex objects', () {
      final testObject = {'name': 'Test', 'value': 123};

      cache.set('obj', testObject);

      final retrieved = cache.get<Map<String, dynamic>>('obj');
      expect(retrieved, testObject);
      expect(retrieved?['name'], 'Test');
      expect(retrieved?['value'], 123);
    });

    test('allows updating existing key', () {
      cache.set('key1', 'value1');
      expect(cache.get<String>('key1'), 'value1');

      cache.set('key1', 'value2');
      expect(cache.get<String>('key1'), 'value2');
    });

    test('invalidates specific key', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      expect(cache.get<String>('key1'), 'value1');
      expect(cache.get<String>('key2'), 'value2');

      cache.invalidate('key1');

      expect(cache.get<String>('key1'), null);
      expect(cache.get<String>('key2'), 'value2');
    });

    test('provides cache statistics', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      cache.get<String>('key1'); // hit
      cache.get<String>('key1'); // hit
      cache.get<String>('nonexistent'); // miss

      final stats = cache.stats;

      expect(stats['size'], 2);
      expect(stats['maxSize'], 3);
      expect(stats['hitRate'], closeTo(0.67, 0.01)); // 2 hits / 3 requests
    });
  });
}
