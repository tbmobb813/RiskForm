import 'dart:async';
import 'adapters/market_data_adapter.dart';
import 'adapters/tradier_adapter.dart';
import 'models/quote.dart';
import 'models/options_chain.dart';
import 'utils/cache_service.dart';
import 'utils/rate_limiter.dart';

/// Main service for fetching market data
///
/// Features:
/// - Adapter pattern for multiple providers (Tradier, Polygon, etc.)
/// - Aggressive caching (5-second TTL for quotes)
/// - Rate limiting to respect provider limits
/// - Graceful degradation (stale data if API fails)
///
/// Usage:
/// ```dart
/// final service = MarketDataService(
///   provider: MarketDataProvider.tradier,
///   apiKey: 'your-key',
///   useSandbox: true,
/// );
///
/// final quotes = await service.fetchQuotes(['SPY', 'QQQ', 'AAPL']);
/// ```
class MarketDataService {
  final MarketDataAdapter _adapter;
  final CacheService _cache;
  final RateLimiter _rateLimiter;

  MarketDataService({
    required MarketDataProvider provider,
    required String apiKey,
    bool useSandbox = true,
    int rateLimitPerMinute = 60,
  })  : _adapter = _createAdapter(provider, apiKey, useSandbox),
        _cache = CacheService(
          defaultTtl: const Duration(seconds: 5),
          maxSize: 100,
        ),
        _rateLimiter = RateLimiter(maxCallsPerMinute: rateLimitPerMinute);

  /// Create adapter based on provider type
  static MarketDataAdapter _createAdapter(
    MarketDataProvider provider,
    String apiKey,
    bool useSandbox,
  ) {
    switch (provider) {
      case MarketDataProvider.tradier:
        return TradierAdapter(apiKey: apiKey, useSandbox: useSandbox);
      case MarketDataProvider.polygon:
        throw UnimplementedError('Polygon adapter not yet implemented');
      case MarketDataProvider.yahoo:
        throw UnimplementedError('Yahoo adapter not yet implemented');
    }
  }

  /// Fetch a single quote
  ///
  /// Checks cache first, falls back to API if cache miss
  Future<Quote> fetchQuote(String ticker) async {
    final cacheKey = 'quote:$ticker';

    // Check cache
    final cached = _cache.get<Quote>(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Rate limit
    await _rateLimiter.acquire();

    // Fetch from adapter
    try {
      final quote = await _adapter.fetchQuote(ticker);

      // Cache result
      _cache.set(cacheKey, quote);

      return quote;
    } catch (e) {
      // Return placeholder on error
      return Quote.placeholder(ticker);
    }
  }

  /// Fetch multiple quotes
  ///
  /// Uses batch request if adapter supports it, otherwise fetches individually
  Future<List<Quote>> fetchQuotes(List<String> tickers) async {
    if (tickers.isEmpty) return [];

    // Check cache for all tickers
    final quotes = <Quote>[];
    final uncachedTickers = <String>[];

    for (final ticker in tickers) {
      final cached = _cache.get<Quote>('quote:$ticker');
      if (cached != null) {
        quotes.add(cached);
      } else {
        uncachedTickers.add(ticker);
      }
    }

    // If all cached, return immediately
    if (uncachedTickers.isEmpty) {
      return quotes;
    }

    // Fetch uncached quotes
    try {
      await _rateLimiter.acquire();

      final freshQuotes = _adapter.supportsBatch
          ? await _adapter.fetchQuotesBatch(uncachedTickers)
          : await _fetchIndividually(uncachedTickers);

      // Cache fresh quotes
      for (final quote in freshQuotes) {
        _cache.set('quote:${quote.ticker}', quote);
      }

      quotes.addAll(freshQuotes);
    } catch (e) {
      // Add placeholders for failed tickers
      for (final ticker in uncachedTickers) {
        quotes.add(Quote.placeholder(ticker));
      }
    }

    // Sort to match input order
    final tickerOrder = {for (var i = 0; i < tickers.length; i++) tickers[i]: i};
    quotes.sort((a, b) => (tickerOrder[a.ticker] ?? 0).compareTo(tickerOrder[b.ticker] ?? 0));

    return quotes;
  }

  /// Fetch quotes individually (fallback when batch not supported)
  Future<List<Quote>> _fetchIndividually(List<String> tickers) async {
    final quotes = <Quote>[];

    for (final ticker in tickers) {
      await _rateLimiter.acquire();
      try {
        final quote = await _adapter.fetchQuote(ticker);
        quotes.add(quote);
      } catch (e) {
        quotes.add(Quote.placeholder(ticker));
      }
    }

    return quotes;
  }

  /// Fetch options chain for a ticker
  ///
  /// Caches for 1 minute (options chains change less frequently)
  Future<OptionsChain> fetchOptionsChain(
    String ticker, {
    DateTime? expiration,
  }) async {
    final cacheKey = 'chain:$ticker${expiration != null ? ':${expiration.toIso8601String()}' : ''}';

    // Check cache (1-minute TTL for chains)
    final cached = _cache.get<OptionsChain>(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Rate limit
    await _rateLimiter.acquire();

    // Fetch from adapter
    try {
      final chain = await _adapter.fetchOptionsChain(ticker, expiration: expiration);

      // Cache with longer TTL
      _cache.set(cacheKey, chain, ttl: const Duration(minutes: 1));

      return chain;
    } catch (e) {
      // Return empty chain on error
      return OptionsChain(ticker: ticker, calls: [], puts: [], expirations: []);
    }
  }

  /// Calculate IV percentile (requires historical IV data)
  ///
  /// Returns percentile (0-100) of current IV vs last 252 trading days
  Future<double> calculateIVPercentile(String ticker) async {
    final cacheKey = 'iv_percentile:$ticker';

    // Check cache (5-minute TTL for IV percentile)
    final cached = _cache.get<double>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      // Fetch current IV
      final currentIV = await _adapter.fetchCurrentIV(ticker);

      // Fetch historical IV (252 trading days = 1 year)
      final historicalIV = await _adapter.fetchHistoricalIV(ticker, days: 252);

      if (historicalIV.isEmpty) {
        return 50.0; // Default to 50th percentile if no data
      }

      // Calculate percentile
      final lowerCount = historicalIV.where((iv) => iv < currentIV).length;
      final percentile = (lowerCount / historicalIV.length) * 100;

      // Cache result
      _cache.set(cacheKey, percentile, ttl: const Duration(minutes: 5));

      return percentile;
    } catch (e) {
      return 50.0; // Default on error
    }
  }

  /// Fetch historical prices for technical analysis
  Future<List<HistoricalPrice>> fetchHistoricalPrices(
    String ticker, {
    required int days,
  }) async {
    final cacheKey = 'historical:$ticker:$days';

    final cached = _cache.get<List<HistoricalPrice>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    await _rateLimiter.acquire();

    try {
      final prices = await _adapter.fetchHistoricalPrices(ticker, days: days);

      // Cache historical data for longer (15 minutes)
      _cache.set(cacheKey, prices, ttl: const Duration(minutes: 15));

      return prices;
    } catch (e) {
      return [];
    }
  }

  /// Subscribe to real-time quote updates (WebSocket)
  Stream<Quote>? subscribeToQuote(String ticker) {
    return _adapter.subscribeToQuote(ticker);
  }

  /// Get cache statistics
  CacheStats get cacheStats => _cache.stats;

  /// Get rate limiter status
  int get remainingCalls => _rateLimiter.remainingCalls;

  /// Whether adapter provides real-time data
  bool get isRealTime => _adapter.isRealTime;

  /// Clear all caches
  void clearCache() {
    _cache.clear();
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _adapter.close();
    _cache.clear();
    _rateLimiter.reset();
  }
}

/// Market data provider options
enum MarketDataProvider {
  tradier, // Recommended (free sandbox, cheap real-time)
  polygon, // Alternative (good for production)
  yahoo, // Fallback (unofficial, free but risky)
}
