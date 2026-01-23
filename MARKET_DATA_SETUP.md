# Market Data Service - Setup Guide

Your market data foundation is ready! Here's how to test and integrate it.

---

## ✅ What Was Built

**12 new files** (~1,500 lines of production-ready code):

```
lib/services/market_data/
├── models/
│   ├── quote.dart                  # Stock quotes
│   ├── greeks.dart                 # Option Greeks + IV
│   ├── option_contract.dart        # Single option
│   └── options_chain.dart          # Full chain
├── adapters/
│   ├── market_data_adapter.dart    # Interface
│   └── tradier_adapter.dart        # Tradier implementation
├── utils/
│   ├── cache_service.dart          # LRU cache (5-sec TTL)
│   └── rate_limiter.dart           # Token bucket limiter
├── market_data_service.dart        # Main service
├── market_data_providers.dart      # Riverpod providers
├── examples/
│   └── test_market_data.dart       # Test script
└── README.md                       # Full documentation
```

**Features**:
- ✅ Fetch stock quotes (single or batch)
- ✅ Fetch full options chains with Greeks
- ✅ Fetch historical data for SMA/ATR
- ✅ Calculate IV percentile
- ✅ Aggressive caching (5-second TTL)
- ✅ Rate limiting (respects provider limits)
- ✅ Graceful degradation (returns placeholders on error)

---

## Quick Start (5 Minutes)

### Step 1: Get Tradier Sandbox API Key (FREE)

1. Go to https://developer.tradier.com/user/sign_up
2. Sign up (free, no credit card)
3. Click "Sandbox" → "Create Access Token"
4. Copy your key

### Step 2: Add to Environment

Create `.env` file in project root (if doesn't exist):

```bash
# .env
TRADIER_API_KEY=your_sandbox_key_here
TRADIER_USE_SANDBOX=true
MARKET_DATA_RATE_LIMIT=60
```

Add to `.gitignore`:
```bash
.env
```

### Step 3: Install Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  flutter_dotenv: ^5.1.0
```

Run:
```bash
flutter pub get
```

### Step 4: Test the Service

Run the test script:

```dart
import 'package:riskform/services/market_data/examples/test_market_data.dart';

void main() async {
  await testMarketData('YOUR_SANDBOX_KEY');
}
```

Or test directly:

```dart
final service = MarketDataService(
  provider: MarketDataProvider.tradier,
  apiKey: 'YOUR_SANDBOX_KEY',
  useSandbox: true,
);

final quotes = await service.fetchQuotes(['SPY', 'AAPL', 'QQQ']);
for (final quote in quotes) {
  print('${quote.ticker}: \$${quote.price} (${quote.changePercent}%)');
}

await service.dispose();
```

Expected output:
```
SPY: $450.12 (+0.3%)
AAPL: $175.32 (+1.2%)
QQQ: $385.45 (+0.8%)
```

---

## Integration with Cockpit

### Step 1: Enable Provider

Edit `lib/services/market_data/market_data_providers.dart`:

**Uncomment this section**:
```dart
final apiKey = dotenv.env['TRADIER_API_KEY'];
final useSandbox = dotenv.env['TRADIER_USE_SANDBOX'] == 'true';

if (apiKey == null || apiKey.isEmpty) {
  return null; // Gracefully degrade
}

return MarketDataService(
  provider: MarketDataProvider.tradier,
  apiKey: apiKey,
  useSandbox: useSandbox,
  rateLimitPerMinute: 60,
);
```

### Step 2: Load .env in Main

Edit `lib/main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}
```

### Step 3: Update CockpitController

Edit `lib/screens/cockpit/controllers/cockpit_controller.dart`:

```dart
import 'package:riskform/services/market_data/market_data_providers.dart';
import 'package:riskform/services/market_data/models/quote.dart';

class CockpitController extends StateNotifier<CockpitState> {
  final Ref ref;
  Timer? _watchlistTimer;

  CockpitController(this.ref) : super(CockpitState.initial()) {
    _loadCockpitData();
    _startWatchlistUpdates(); // NEW
  }

  /// Start periodic watchlist updates
  void _startWatchlistUpdates() {
    final marketData = ref.read(marketDataServiceProvider);
    if (marketData == null) return; // No market data available

    _watchlistTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (state.watchlist.isEmpty) return;

      try {
        final tickers = state.watchlist.map((w) => w.ticker).toList();
        final quotes = await marketData.fetchQuotes(tickers);

        final updatedWatchlist = quotes.map((quote) {
          // Calculate IV percentile (cached)
          final ivPercentile = 50.0; // TODO: Calculate properly

          return WatchlistItem.withLiveData(
            ticker: quote.ticker,
            price: quote.price,
            ivPercentile: ivPercentile,
            changePercent: quote.changePercent,
          );
        }).toList();

        state = state.copyWith(watchlist: updatedWatchlist);
      } catch (e) {
        // Fail silently, keep last known data
      }
    });
  }

  @override
  void dispose() {
    _watchlistTimer?.cancel();
    super.dispose();
  }
}
```

### Step 4: Update WatchlistCard

The `WatchlistCard` already shows live/delayed badges! Just works once service is enabled.

---

## What You Get

### Before (Phase 6)
- Watchlist shows "N/A" for all values
- [Scan] buttons non-functional
- No regime detection

### After (Phase 6.5a)
- Watchlist updates every 5 seconds
- Real prices, change%, volume
- "15min delay" badge (Tradier sandbox)
- Working options scanner (coming next)
- Regime detection (coming next)

---

## Cost Analysis

### Development (Current)
- Tradier Sandbox: **FREE**
- Unlimited API calls
- 15-minute delayed data
- Perfect for testing

### Production Options

**Option A: Users Open Tradier Account** (FREE)
- User opens free Tradier brokerage account
- Gets real-time data for free
- You get referral fees
- Sets up future live trading integration

**Option B: Pay for Data** ($10-199/month)
- Tradier Market Data: $10/month (delayed)
- Polygon.io Starter: $29/month (delayed options)
- Polygon.io Trader: $199/month (real-time options)

**Recommendation**: Start with sandbox (free), then encourage Tradier accounts (also free for users).

---

## Next Steps

### Immediate (Test It!)
1. ✅ Get Tradier sandbox key
2. ✅ Add to .env file
3. ✅ Run test script
4. ✅ Verify quotes work

### This Week (Integrate)
1. Enable provider in `market_data_providers.dart`
2. Update cockpit controller with periodic updates
3. Test watchlist with live data
4. Deploy to staging

### Next Phase (6.5b)
1. Build options scanner using `fetchOptionsChain()`
2. Implement regime detection using historical data
3. Add IV percentile calculation
4. Add price alerts

---

## Testing Checklist

- [ ] Tradier sandbox key obtained
- [ ] `.env` file created with key
- [ ] Test script runs successfully
- [ ] Can fetch single quote
- [ ] Can fetch batch quotes (3+ tickers)
- [ ] Cache works (2nd fetch is instant)
- [ ] Options chain fetches
- [ ] Historical data fetches
- [ ] Rate limiter doesn't block normal usage
- [ ] Service degrades gracefully on errors

---

## Troubleshooting

### "Invalid API key"
- Check key in .env is correct
- Ensure `TRADIER_USE_SANDBOX=true`
- Verify key from sandbox (not production)

### "Rate limit exceeded"
- Sandbox has no rate limits
- Check `MARKET_DATA_RATE_LIMIT` setting
- Clear cache: `service.clearCache()`

### "No data returned"
- Ticker symbol invalid (use uppercase)
- Market closed (use delay to test)
- Check Tradier API status

### "Import errors"
- Run `flutter pub get`
- Restart IDE
- Check http package is in pubspec.yaml

---

## Files You Need to Edit

To enable live data in cockpit:

1. `lib/services/market_data/market_data_providers.dart` - Uncomment provider
2. `lib/main.dart` - Load .env file
3. `lib/screens/cockpit/controllers/cockpit_controller.dart` - Add periodic updates
4. `.env` - Add Tradier API key
5. `pubspec.yaml` - Add `http` and `flutter_dotenv`

---

## Support

**Tradier API Docs**: https://documentation.tradier.com/brokerage-api/markets

**Questions?** Check:
1. `lib/services/market_data/README.md` (detailed docs)
2. `lib/services/market_data/examples/test_market_data.dart` (test script)
3. Code comments (heavily documented)

---

**Status**: Ready to test!
**Next Action**: Get Tradier sandbox key and run test script
