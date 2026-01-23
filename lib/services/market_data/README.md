# Market Data Service

Real-time and delayed market data integration for RiskForm.

## Overview

This module provides a unified interface for fetching stock quotes, options chains, and historical data from multiple providers (Tradier, Polygon.io, etc.).

## Architecture

```
MarketDataService (main service)
  ├─ CacheService (5-second TTL)
  ├─ RateLimiter (respects provider limits)
  └─ MarketDataAdapter (strategy pattern)
      ├─ TradierAdapter (implemented)
      ├─ PolygonAdapter (TODO)
      └─ YahooAdapter (TODO)
```

## Quick Start

### 1. Set Up Tradier Sandbox (FREE)

```bash
# 1. Sign up at https://developer.tradier.com/user/sign_up
# 2. Get sandbox API key
# 3. Add to .env file (create if doesn't exist)

# .env
TRADIER_API_KEY=your_sandbox_key_here
TRADIER_USE_SANDBOX=true
```

### 2. Enable Market Data Service

Edit `lib/services/market_data/market_data_providers.dart`:

```dart
// Uncomment these lines:
final apiKey = dotenv.env['TRADIER_API_KEY'];
final useSandbox = dotenv.env['TRADIER_USE_SANDBOX'] == 'true';

if (apiKey == null || apiKey.isEmpty) {
  return null;
}

return MarketDataService(
  provider: MarketDataProvider.tradier,
  apiKey: apiKey,
  useSandbox: useSandbox,
  rateLimitPerMinute: 60,
);
```

### 3. Use in Cockpit

```dart
// In CockpitController
final marketData = ref.read(marketDataServiceProvider);

if (marketData != null) {
  final quotes = await marketData.fetchQuotes(['SPY', 'QQQ', 'AAPL']);

  final updatedWatchlist = quotes.map((quote) =>
    WatchlistItem.withLiveData(
      ticker: quote.ticker,
      price: quote.price,
      ivPercentile: await marketData.calculateIVPercentile(quote.ticker),
      changePercent: quote.changePercent,
    )
  ).toList();

  state = state.copyWith(watchlist: updatedWatchlist);
}
```

## Features

### Quote Fetching

```dart
// Single quote
final quote = await service.fetchQuote('AAPL');
print('AAPL: \$${quote.price} (${quote.changePercent}%)');

// Multiple quotes (batched)
final quotes = await service.fetchQuotes(['SPY', 'QQQ', 'IWM']);
```

### Options Chains

```dart
// Full chain (all expirations)
final chain = await service.fetchOptionsChain('AAPL');
print('${chain.calls.length} calls, ${chain.puts.length} puts');

// Specific expiration
final expiration = DateTime(2024, 1, 20);
final chain = await service.fetchOptionsChain('AAPL', expiration: expiration);

// Filter liquid contracts only
final liquidChain = chain.liquidOnly;

// Find contracts near a strike
final atmContracts = chain.getContractsNearStrike(175.0, delta: 5.0);
```

### IV Percentile

```dart
// Calculate where current IV ranks vs last year
final percentile = await service.calculateIVPercentile('AAPL');

if (percentile > 75) {
  print('IV is high - consider selling premium');
} else if (percentile < 25) {
  print('IV is low - consider buying premium');
}
```

### Historical Data

```dart
// Fetch for technical analysis
final prices = await service.fetchHistoricalPrices('SPY', days: 20);

final sma20 = prices.map((p) => p.close).reduce((a, b) => a + b) / prices.length;
print('SPY 20-day SMA: \$${sma20.toStringAsFixed(2)}');
```

## Caching

All data is cached to minimize API calls:

- **Quotes**: 5-second TTL
- **Options chains**: 1-minute TTL
- **IV percentile**: 5-minute TTL
- **Historical data**: 15-minute TTL

```dart
// Check cache stats
final stats = service.cacheStats;
print('Cache: ${stats.size}/${stats.capacity} (${stats.usagePercent.toStringAsFixed(1)}%)');

// Clear cache manually
service.clearCache();
```

## Rate Limiting

Token bucket algorithm prevents exceeding provider limits:

```dart
// Check remaining calls
print('Remaining calls: ${service.remainingCalls}');

// Service automatically waits if limit reached
await service.fetchQuote('AAPL'); // May pause if at limit
```

## Error Handling

Service fails gracefully:

```dart
// On error, returns placeholder data
final quote = await service.fetchQuote('INVALID');
// Returns: Quote.placeholder('INVALID') with 0.0 values

// On network error, returns cached data if available
// Otherwise returns empty/placeholder data
```

## Providers

### Tradier (Recommended)

**Pricing**:
- Sandbox: FREE, unlimited calls, 15-min delayed
- Real-time: FREE with brokerage account OR $10/month

**Pros**:
- ✅ Best free tier for development
- ✅ Easy path to real-time (open account or $10/month)
- ✅ Built-in brokerage for future live trading

**Setup**:
```dart
MarketDataService(
  provider: MarketDataProvider.tradier,
  apiKey: 'your_key',
  useSandbox: true, // false for real-time
)
```

### Polygon.io (Alternative)

**Pricing**:
- Free: 5 calls/min (too limited)
- Starter ($29/month): Delayed options
- Trader ($199/month): Real-time options

**Setup**: (Not yet implemented)
```dart
MarketDataService(
  provider: MarketDataProvider.polygon,
  apiKey: 'your_key',
)
```

### Yahoo Finance (Fallback)

**Pricing**: FREE (unofficial)

**Risks**:
- ❌ No official API (can break anytime)
- ❌ Rate limiting via IP blocking
- ❌ Terms of service violations

**Setup**: (Not yet implemented)

## Testing

### Unit Tests

```bash
flutter test test/services/market_data/
```

### Integration Tests (Requires API Key)

```bash
# Set up .env with test credentials
TRADIER_API_KEY=your_sandbox_key
TRADIER_USE_SANDBOX=true

flutter test integration_test/market_data_test.dart
```

### Manual Testing

```dart
// Create service with sandbox credentials
final service = MarketDataService(
  provider: MarketDataProvider.tradier,
  apiKey: 'YOUR_SANDBOX_KEY',
  useSandbox: true,
);

// Fetch some quotes
final quotes = await service.fetchQuotes(['SPY', 'AAPL', 'QQQ']);
for (final quote in quotes) {
  print(quote);
}

// Clean up
await service.dispose();
```

## Files

```
lib/services/market_data/
├── models/
│   ├── quote.dart                  # Stock quote model
│   ├── greeks.dart                 # Option Greeks model
│   ├── option_contract.dart        # Single option contract
│   └── options_chain.dart          # Full options chain
├── adapters/
│   ├── market_data_adapter.dart    # Abstract interface
│   └── tradier_adapter.dart        # Tradier implementation
├── utils/
│   ├── cache_service.dart          # LRU cache
│   └── rate_limiter.dart           # Token bucket limiter
├── market_data_service.dart        # Main service
├── market_data_providers.dart      # Riverpod providers
└── README.md                       # This file
```

## Roadmap

### Phase 6.5a (Current)
- ✅ Tradier adapter
- ✅ Caching layer
- ✅ Rate limiting
- ✅ Quote fetching
- ✅ Options chains
- ✅ Historical data

### Phase 6.5b (Next)
- [ ] Polygon adapter
- [ ] WebSocket support for real-time
- [ ] IV percentile calculation (full implementation)
- [ ] Regime detection integration

### Phase 6.5c (Future)
- [ ] Yahoo Finance fallback
- [ ] Advanced caching strategies
- [ ] Circuit breaker pattern
- [ ] Metrics and monitoring

## Support

For issues or questions:
1. Check Tradier API docs: https://documentation.tradier.com/brokerage-api/markets
2. Review code comments (heavily documented)
3. Test with sandbox first before using real-time

---

**Status**: Phase 6.5a - Ready for testing
**Next Action**: Set up Tradier sandbox and test quote fetching
