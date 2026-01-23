# Phase 6.5: Live Market Data Architecture

**Goal**: Integrate real-time market data into the Small Account Cockpit to enable functional watchlist, options scanner, and regime detection.

**Timeline**: 2-3 weeks
**Priority**: High (makes cockpit fully functional)
**Dependencies**: Phase 6 (Small Account Cockpit) ✅

---

## Current State (Phase 6)

### What Works Without Live Data
- ✅ Discipline scoring (from journal entries)
- ✅ Streak tracking
- ✅ Journal blocking
- ✅ Weekly calendar
- ✅ Account snapshot (from providers)

### What Needs Live Data
- ❌ Watchlist shows "N/A" for prices, IV, change%
- ❌ [Scan] buttons are non-functional
- ❌ Regime detection shows placeholder "Sideways"
- ❌ No price alerts
- ❌ No real-time position P/L updates

---

## Market Data Provider Analysis

### Option 1: Polygon.io (RECOMMENDED)

**Pricing**:
- **Free Tier**: 5 API calls/minute (100/day for stocks, 5/day for options)
- **Starter ($29/month)**: Unlimited delayed data (15-min delay for options)
- **Developer ($99/month)**: Real-time stocks, delayed options
- **Trader ($199/month)**: Real-time stocks + options

**Pros**:
- ✅ Excellent API documentation
- ✅ WebSocket support for real-time
- ✅ REST API for historical data
- ✅ Options chain data with Greeks
- ✅ Good free tier for development
- ✅ Used by major fintech apps

**Cons**:
- ❌ Real-time options data expensive ($199/month)
- ❌ Rate limits on free tier very tight
- ❌ 15-minute delay on affordable tiers

**Best For**: Production with $99-$199/month budget

**Free Tier Viability**: ⚠️ Only for development/testing (5 calls/min = 1 ticker update every 12 seconds)

---

### Option 2: Tradier (STRONG ALTERNATIVE)

**Pricing**:
- **Free Sandbox**: Unlimited calls (delayed data)
- **Free with Brokerage**: Real-time if you open a Tradier brokerage account (no minimum balance)
- **Market Data ($10/month)**: Real-time quotes without brokerage account

**Pros**:
- ✅ **FREE real-time data with brokerage account** (huge win)
- ✅ Unlimited API calls in sandbox
- ✅ Options chain with Greeks
- ✅ Built-in brokerage integration (future live trading)
- ✅ WebSocket + REST support
- ✅ Very generous rate limits

**Cons**:
- ❌ Requires brokerage account for free real-time (friction for users)
- ❌ API documentation less polished than Polygon
- ❌ Smaller community/fewer code examples

**Best For**: Small account users who can open a free Tradier account

**Free Tier Viability**: ✅ Excellent (unlimited sandbox, free real-time with account)

---

### Option 3: Alpha Vantage (BUDGET OPTION)

**Pricing**:
- **Free Tier**: 25 API calls/day
- **Premium ($49.99/month)**: 75 calls/minute
- **Premium+ ($149.99/month)**: 300 calls/minute

**Pros**:
- ✅ Very simple API
- ✅ Good for intraday stock data
- ✅ Affordable premium tier

**Cons**:
- ❌ Limited options data (no full chains)
- ❌ No WebSocket (REST only)
- ❌ 25 calls/day free tier is very limited
- ❌ No Greeks in free tier

**Best For**: Stock-only features (not suitable for options platform)

**Free Tier Viability**: ❌ Too limited (25 calls/day = can't even update 5-ticker watchlist every hour)

---

### Option 4: Yahoo Finance (Unofficial API)

**Pricing**: FREE (unofficial)

**Pros**:
- ✅ Completely free
- ✅ No API key required
- ✅ Options chain data available
- ✅ Real-time (15-min delayed) data

**Cons**:
- ❌ **No official API** (can break at any time)
- ❌ No WebSocket support
- ❌ Rate limiting enforced via IP blocking
- ❌ Terms of service violations risk
- ❌ No SLA or support

**Best For**: Prototype/MVP only (too risky for production)

**Free Tier Viability**: ✅ For MVP, ❌ for production

---

## Recommendation: Hybrid Approach

### Phase 6.5a (MVP - FREE)
**Use**: Tradier Sandbox (unlimited, delayed data)
- Perfect for development and testing
- No cost
- All features work (just 15-min delayed)
- Smooth path to real-time when users open Tradier account

### Phase 6.5b (Production - $10-$199/month)
**Use**: Tradier Real-Time ($10/month) OR Polygon.io ($99-$199/month)
- **Tradier**: Best value if users willing to open brokerage account (free!)
- **Polygon**: Best for users who want data-only (no brokerage)

### Fallback
**Use**: Yahoo Finance (unofficial) as fallback when official APIs fail
- Graceful degradation
- Show "delayed data" badge

---

## Architecture Design

### Data Flow

```
User opens cockpit
  ↓
CockpitController loads state
  ↓
MarketDataService.fetchWatchlist(tickers)
  ↓
┌─────────────────────────────────────────┐
│ MarketDataService (Singleton)           │
│                                          │
│  ├─ CacheLayer (5-second TTL)          │
│  │   └─ In-memory LRU cache             │
│  │                                       │
│  ├─ ProviderAdapter (strategy pattern) │
│  │   ├─ TradierAdapter                  │
│  │   ├─ PolygonAdapter                  │
│  │   └─ YahooAdapter (fallback)         │
│  │                                       │
│  └─ RateLimiter (token bucket)          │
│      └─ Respect provider rate limits    │
└─────────────────────────────────────────┘
  ↓
REST API call to provider
  ↓
Response parsed to WatchlistItem
  ↓
State updated (triggers UI rebuild)
```

### Key Components

#### 1. MarketDataService

```dart
class MarketDataService {
  final MarketDataAdapter _adapter;
  final CacheService _cache;
  final RateLimiter _rateLimiter;

  MarketDataService({
    required MarketDataProvider provider,
  }) : _adapter = _createAdapter(provider),
       _cache = CacheService(ttl: Duration(seconds: 5)),
       _rateLimiter = RateLimiter(maxCallsPerMinute: 60);

  /// Fetch current quote for a single ticker
  Future<Quote> fetchQuote(String ticker) async {
    // Check cache first
    final cached = _cache.get('quote:$ticker');
    if (cached != null) return cached;

    // Rate limit
    await _rateLimiter.acquire();

    // Fetch from adapter
    final quote = await _adapter.fetchQuote(ticker);

    // Cache result
    _cache.set('quote:$ticker', quote);

    return quote;
  }

  /// Fetch quotes for multiple tickers (batched)
  Future<List<Quote>> fetchQuotes(List<String> tickers) async {
    // Check if adapter supports batch requests
    if (_adapter.supportsBatch) {
      return await _adapter.fetchQuotesBatch(tickers);
    }

    // Otherwise, fetch individually with rate limiting
    final quotes = <Quote>[];
    for (final ticker in tickers) {
      quotes.add(await fetchQuote(ticker));
    }
    return quotes;
  }

  /// Fetch full options chain for a ticker
  Future<OptionsChain> fetchOptionsChain(String ticker) async {
    final cached = _cache.get('chain:$ticker');
    if (cached != null) return cached;

    await _rateLimiter.acquire();
    final chain = await _adapter.fetchOptionsChain(ticker);

    _cache.set('chain:$ticker', chain, ttl: Duration(minutes: 1));
    return chain;
  }

  /// Calculate IV percentile (requires historical IV data)
  Future<double> calculateIVPercentile(String ticker) async {
    final historicalIV = await _adapter.fetchHistoricalIV(ticker, days: 252);
    final currentIV = await _adapter.fetchCurrentIV(ticker);

    return _calculatePercentile(currentIV, historicalIV);
  }
}
```

#### 2. MarketDataAdapter (Strategy Pattern)

```dart
abstract class MarketDataAdapter {
  bool get supportsBatch;
  bool get supportsWebSocket;

  Future<Quote> fetchQuote(String ticker);
  Future<List<Quote>> fetchQuotesBatch(List<String> tickers);
  Future<OptionsChain> fetchOptionsChain(String ticker);
  Future<List<double>> fetchHistoricalIV(String ticker, {required int days});
  Future<double> fetchCurrentIV(String ticker);

  Stream<Quote>? subscribeToQuote(String ticker);
}

class TradierAdapter implements MarketDataAdapter {
  final String apiKey;
  final bool useSandbox;
  final http.Client _client;

  TradierAdapter({
    required this.apiKey,
    this.useSandbox = false,
  }) : _client = http.Client();

  String get _baseUrl => useSandbox
    ? 'https://sandbox.tradier.com/v1'
    : 'https://api.tradier.com/v1';

  @override
  bool get supportsBatch => true;

  @override
  Future<Quote> fetchQuote(String ticker) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/markets/quotes?symbols=$ticker'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw MarketDataException('Failed to fetch quote: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return Quote.fromTradierJson(data['quotes']['quote']);
  }

  @override
  Future<List<Quote>> fetchQuotesBatch(List<String> tickers) async {
    final symbols = tickers.join(',');
    final response = await _client.get(
      Uri.parse('$_baseUrl/markets/quotes?symbols=$symbols'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    );

    final data = json.decode(response.body);
    final quotes = data['quotes']['quote'] as List;
    return quotes.map((q) => Quote.fromTradierJson(q)).toList();
  }

  @override
  Future<OptionsChain> fetchOptionsChain(String ticker) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/markets/options/chains?symbol=$ticker&greeks=true'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    );

    final data = json.decode(response.body);
    return OptionsChain.fromTradierJson(data);
  }

  // ... other methods
}
```

#### 3. Quote Model

```dart
class Quote {
  final String ticker;
  final double price;
  final double change;
  final double changePercent;
  final double open;
  final double high;
  final double low;
  final double volume;
  final DateTime timestamp;
  final bool isDelayed;

  Quote({
    required this.ticker,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.timestamp,
    this.isDelayed = false,
  });

  factory Quote.fromTradierJson(Map<String, dynamic> json) {
    return Quote(
      ticker: json['symbol'],
      price: (json['last'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['change_percentage'] as num).toDouble(),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      timestamp: DateTime.now(),
      isDelayed: false, // Tradier sandbox is delayed
    );
  }

  factory Quote.fromPolygonJson(Map<String, dynamic> json) {
    // Polygon format
    return Quote(
      ticker: json['T'],
      price: (json['c'] as num).toDouble(),
      change: (json['c'] - json['o'] as num).toDouble(),
      changePercent: ((json['c'] - json['o']) / json['o'] * 100).toDouble(),
      open: (json['o'] as num).toDouble(),
      high: (json['h'] as num).toDouble(),
      low: (json['l'] as num).toDouble(),
      volume: (json['v'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['t']),
      isDelayed: false,
    );
  }
}
```

#### 4. OptionsChain Model

```dart
class OptionsChain {
  final String ticker;
  final List<OptionContract> calls;
  final List<OptionContract> puts;
  final DateTime expirationDate;

  OptionsChain({
    required this.ticker,
    required this.calls,
    required this.puts,
    required this.expirationDate,
  });
}

class OptionContract {
  final String symbol;
  final double strike;
  final String type; // "call" or "put"
  final DateTime expiration;
  final double bid;
  final double ask;
  final double last;
  final double volume;
  final double openInterest;
  final Greeks? greeks;

  OptionContract({
    required this.symbol,
    required this.strike,
    required this.type,
    required this.expiration,
    required this.bid,
    required this.ask,
    required this.last,
    required this.volume,
    required this.openInterest,
    this.greeks,
  });

  double get midpoint => (bid + ask) / 2;
  bool get isLiquid => openInterest > 100 && volume > 10;
}

class Greeks {
  final double delta;
  final double gamma;
  final double theta;
  final double vega;
  final double rho;
  final double iv; // Implied volatility

  Greeks({
    required this.delta,
    required this.gamma,
    required this.theta,
    required this.vega,
    required this.rho,
    required this.iv,
  });
}
```

---

## Integration with Cockpit

### Update CockpitController

```dart
class CockpitController extends StateNotifier<CockpitState> {
  final Ref ref;
  final MarketDataService? _marketData; // Optional (graceful degradation)

  CockpitController(this.ref) :
    _marketData = ref.read(marketDataServiceProvider),
    super(CockpitState.initial()) {
    _loadCockpitData();
    _startWatchlistUpdates(); // NEW
  }

  /// Start periodic watchlist updates (every 5 seconds)
  void _startWatchlistUpdates() {
    if (_marketData == null) return; // No market data service available

    Timer.periodic(Duration(seconds: 5), (timer) async {
      if (state.watchlist.isEmpty) return;

      try {
        final tickers = state.watchlist.map((w) => w.ticker).toList();
        final quotes = await _marketData!.fetchQuotes(tickers);

        final updatedWatchlist = quotes.map((quote) {
          // Calculate IV percentile (cached)
          final ivPercentile = _calculateIVPercentile(quote.ticker);

          return WatchlistItem.withLiveData(
            ticker: quote.ticker,
            price: quote.price,
            ivPercentile: ivPercentile,
            changePercent: quote.changePercent,
          );
        }).toList();

        state = state.copyWith(watchlist: updatedWatchlist);
      } catch (e) {
        // Fail silently, keep showing last known data
        print('Failed to update watchlist: $e');
      }
    });
  }

  Future<double> _calculateIVPercentile(String ticker) async {
    try {
      return await _marketData!.calculateIVPercentile(ticker);
    } catch (e) {
      return 50.0; // Default to 50th percentile on error
    }
  }
}
```

### Update WatchlistCard Widget

```dart
// In watchlist_card.dart
Widget _buildWatchlistRow(BuildContext context, WatchlistItem item) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        // Ticker
        SizedBox(
          width: 60,
          child: Text(
            item.ticker,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Price with live/delayed indicator
        SizedBox(
          width: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.priceDisplay,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (item.hasLiveData && item.isDelayed)
                const Text(
                  '15min delay',
                  style: TextStyle(fontSize: 9, color: Colors.orange),
                ),
            ],
          ),
        ),

        // IV Percentile with color coding
        SizedBox(
          width: 70,
          child: Row(
            children: [
              Text('IV: ', style: TextStyle(fontSize: 12)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getIVColor(item.ivPercentile).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.ivDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getIVColor(item.ivPercentile),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Change %
        SizedBox(
          width: 70,
          child: Text(
            item.changeDisplay,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: item.isPositive
                  ? Colors.green
                  : item.isNegative
                      ? Colors.red
                      : Colors.black54,
            ),
          ),
        ),

        const Spacer(),

        // Scan button (now functional!)
        TextButton(
          onPressed: () => onScanTap(item.ticker),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            backgroundColor: Colors.blue.shade50,
          ),
          child: const Text('Scan', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}

Color _getIVColor(double? percentile) {
  if (percentile == null) return Colors.grey;
  if (percentile >= 75) return Colors.red; // High IV
  if (percentile >= 50) return Colors.orange;
  if (percentile >= 25) return Colors.blue;
  return Colors.green; // Low IV
}
```

---

## Regime Detection with Live Data

### RegimeService Implementation

```dart
class RegimeService {
  final MarketDataService _marketData;

  RegimeService(this._marketData);

  Future<MarketRegime> detectRegime() async {
    try {
      // Fetch SPY data (market proxy)
      final spyQuote = await _marketData.fetchQuote('SPY');

      // Fetch 20-day SMA (requires historical data)
      final sma20 = await _calculateSMA('SPY', days: 20);

      // Fetch ATR for volatility
      final atr = await _calculateATR('SPY', days: 14);

      // Regime logic
      if (spyQuote.price > sma20 * 1.02) {
        // Price 2% above SMA = Uptrend
        return atr > 10 ? MarketRegime.volatile : MarketRegime.uptrend;
      } else if (spyQuote.price < sma20 * 0.98) {
        // Price 2% below SMA = Downtrend
        return atr > 10 ? MarketRegime.volatile : MarketRegime.downtrend;
      } else {
        // Within 2% of SMA = Sideways
        return MarketRegime.sideways;
      }
    } catch (e) {
      return MarketRegime.unknown;
    }
  }

  Future<double> _calculateSMA(String ticker, {required int days}) async {
    // Fetch historical data and calculate SMA
    // Implementation depends on adapter
    final historical = await _marketData.adapter.fetchHistoricalPrices(ticker, days: days);
    return historical.map((p) => p.close).reduce((a, b) => a + b) / days;
  }

  Future<double> _calculateATR(String ticker, {required int days}) async {
    // Fetch historical data and calculate Average True Range
    // Formula: ATR = average(high - low) over N days
    final historical = await _marketData.adapter.fetchHistoricalPrices(ticker, days: days);
    final ranges = historical.map((p) => p.high - p.low).toList();
    return ranges.reduce((a, b) => a + b) / days;
  }
}
```

---

## Cost Analysis

### Development (Phase 6.5a)
- **Tradier Sandbox**: FREE (unlimited delayed data)
- **Development time**: 2-3 weeks (1 developer)
- **Total cost**: $0

### Production Options

#### Option A: Budget (For Users Who Open Tradier Account)
- **Tradier Real-Time**: FREE (requires brokerage account)
- **Monthly cost**: $0
- **Tradeoff**: Users must open account (friction)
- **Best for**: Users serious about trading

#### Option B: Paid Data-Only (No Brokerage Required)
- **Tradier Market Data**: $10/month
- **OR Polygon Starter**: $29/month (delayed options)
- **OR Polygon Developer**: $99/month (delayed options)
- **OR Polygon Trader**: $199/month (real-time options)

#### Cost Per User (if you pay for data):
- At 100 users: $1-$2/user/month
- At 1000 users: $0.10-$0.20/user/month
- At 10000 users: $0.01-$0.02/user/month

**Monetization to cover costs**:
- Charge $5-10/month for live data access
- Or: Require users to open Tradier account (free for them, you get referral)

---

## Implementation Steps

### Week 1: Foundation
1. ✅ Create `MarketDataService` interface
2. ✅ Implement `TradierAdapter` (sandbox mode)
3. ✅ Add caching layer (LRU with 5-second TTL)
4. ✅ Add rate limiter (token bucket)
5. ✅ Create `Quote` and `OptionsChain` models
6. ✅ Write unit tests for adapter

### Week 2: Integration
1. ✅ Update `CockpitController` to fetch live data
2. ✅ Update `WatchlistCard` to display live prices
3. ✅ Add "delayed" badge for non-real-time data
4. ✅ Implement IV percentile calculation
5. ✅ Update `RegimeService` with live data
6. ✅ Test with Tradier sandbox

### Week 3: Polish & Deploy
1. ✅ Add error handling and graceful degradation
2. ✅ Implement `PolygonAdapter` as alternative
3. ✅ Add provider selection in settings
4. ✅ Build options scanner screen (using live chains)
5. ✅ Add price alerts
6. ✅ Deploy to production (Tradier sandbox initially)

---

## Testing Strategy

### Unit Tests
- Mock `MarketDataAdapter` responses
- Test caching behavior
- Test rate limiting
- Test graceful degradation

### Integration Tests
- Test with Tradier sandbox (real API)
- Test watchlist updates
- Test options chain fetching
- Test regime detection

### Load Tests
- Simulate 100 concurrent users
- Verify rate limiting works
- Check cache hit rates

---

## Rollout Plan

### Phase 6.5a: MVP (Week 1-2)
- Deploy with Tradier sandbox (delayed data)
- Free for all users
- Shows "15-min delayed" badge
- Validates architecture

### Phase 6.5b: Beta (Week 3)
- Offer real-time to users who open Tradier account
- Track adoption rate
- Gather feedback

### Phase 6.5c: Production (Week 4+)
- Based on adoption, decide:
  - **Option A**: Encourage Tradier accounts (free for users)
  - **Option B**: Charge $5-10/month for live data (use Polygon)
  - **Option C**: Hybrid (free delayed, paid real-time)

---

## Risks & Mitigation

### Risk 1: API Rate Limits
**Mitigation**:
- Implement aggressive caching (5-second TTL)
- Batch requests where possible
- Show stale data rather than no data

### Risk 2: Provider Downtime
**Mitigation**:
- Fallback to Yahoo Finance (unofficial)
- Show "delayed data" warning
- Cache last known good data

### Risk 3: Cost Overruns
**Mitigation**:
- Start with Tradier sandbox (free)
- Monitor API usage closely
- Gate real-time behind user action (open account or pay)

### Risk 4: Users Don't Want to Open Brokerage Account
**Mitigation**:
- Make delayed data the default (free)
- Real-time is optional upgrade
- Clearly explain benefits

---

## Success Metrics

### Technical
- [ ] Watchlist updates every 5 seconds
- [ ] 95%+ cache hit rate
- [ ] <100ms API response time (cached)
- [ ] <500ms API response time (uncached)
- [ ] 99.9% uptime

### User
- [ ] 50%+ of users add tickers to watchlist
- [ ] 25%+ of users use options scanner
- [ ] 10%+ of users open Tradier account for real-time
- [ ] <1% complaints about data accuracy

---

## Configuration

### Environment Variables

```bash
# Market data provider (tradier, polygon, yahoo)
MARKET_DATA_PROVIDER=tradier

# Tradier
TRADIER_API_KEY=your_api_key
TRADIER_USE_SANDBOX=true

# Polygon (alternative)
POLYGON_API_KEY=your_api_key

# Cache settings
MARKET_DATA_CACHE_TTL=5  # seconds
MARKET_DATA_RATE_LIMIT=60  # calls per minute
```

### Settings UI

Add to app settings:

```dart
ListTile(
  title: Text('Market Data Provider'),
  subtitle: Text('Choose your data source'),
  trailing: DropdownButton<MarketDataProvider>(
    value: currentProvider,
    items: [
      DropdownMenuItem(value: MarketDataProvider.tradier, child: Text('Tradier (Free Sandbox)')),
      DropdownMenuItem(value: MarketDataProvider.polygon, child: Text('Polygon.io')),
      DropdownMenuItem(value: MarketDataProvider.yahoo, child: Text('Yahoo Finance (Fallback)')),
    ],
    onChanged: (provider) => updateProvider(provider),
  ),
),
```

---

## Next Phase: Phase 7

After live data is working:
- **Phase 7a**: Paper trading with real-time discipline tracking
- **Phase 7b**: Live trading integration (Tradier brokerage API)
- **Phase 7c**: AI behavior coach (analyzes discipline patterns)

---

## Appendix: Code Examples

### Creating MarketDataService

```dart
final marketDataServiceProvider = Provider<MarketDataService?>((ref) {
  try {
    final provider = MarketDataProvider.tradier; // From settings
    final apiKey = dotenv.env['TRADIER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return null; // Graceful degradation
    }

    return MarketDataService(provider: provider, apiKey: apiKey);
  } catch (e) {
    return null;
  }
});
```

### Using in Cockpit

```dart
final marketData = ref.read(marketDataServiceProvider);

if (marketData != null) {
  final quotes = await marketData.fetchQuotes(['SPY', 'QQQ', 'AAPL']);
  // Update watchlist
} else {
  // Show placeholder data
}
```

---

**Status**: Ready for implementation
**Next Action**: Create `lib/services/market_data/` directory and start with `market_data_service.dart`
