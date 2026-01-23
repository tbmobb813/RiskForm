import '../market_data_service.dart';

/// Simple test script to verify market data service works
///
/// Usage:
/// ```dart
/// await testMarketData('YOUR_TRADIER_SANDBOX_KEY');
/// ```
Future<void> testMarketData(String apiKey) async {
  print('🧪 Testing Market Data Service with Tradier Sandbox\n');

  // Create service
  final service = MarketDataService(
    provider: MarketDataProvider.tradier,
    apiKey: apiKey,
    useSandbox: true,
    rateLimitPerMinute: 60,
  );

  try {
    // Test 1: Single quote
    print('📊 Test 1: Fetching single quote for SPY...');
    final spyQuote = await service.fetchQuote('SPY');
    print('✅ SPY: \$${spyQuote.price} (${spyQuote.changePercent >= 0 ? '+' : ''}${spyQuote.changePercent.toStringAsFixed(2)}%)');
    print('   Delayed: ${spyQuote.isDelayed}\n');

    // Test 2: Batch quotes
    print('📊 Test 2: Fetching batch quotes for SPY, QQQ, AAPL...');
    final quotes = await service.fetchQuotes(['SPY', 'QQQ', 'AAPL']);
    for (final quote in quotes) {
      print('✅ ${quote.ticker}: \$${quote.price} (${quote.changePercent >= 0 ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%)');
    }
    print('');

    // Test 3: Cache hit
    print('📊 Test 3: Testing cache (should be instant)...');
    final start = DateTime.now();
    final cachedQuotes = await service.fetchQuotes(['SPY', 'QQQ', 'AAPL']);
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    print('✅ Cached fetch took ${elapsed}ms');
    print('   Cache stats: ${service.cacheStats.size} items, ${service.cacheStats.usagePercent.toStringAsFixed(1)}% full\n');

    // Test 4: Options chain
    print('📊 Test 4: Fetching options chain for AAPL...');
    final chain = await service.fetchOptionsChain('AAPL');
    print('✅ AAPL chain: ${chain.calls.length} calls, ${chain.puts.length} puts');
    print('   Expirations: ${chain.expirations.length}');
    if (chain.expirations.isNotEmpty) {
      print('   Nearest: ${chain.expirations.first}');
    }

    // Show a few contracts
    if (chain.calls.isNotEmpty) {
      print('\n   Sample calls:');
      for (final call in chain.calls.take(3)) {
        print('     ${call.displayName}: Bid \$${call.bid.toStringAsFixed(2)}, Ask \$${call.ask.toStringAsFixed(2)}');
      }
    }
    print('');

    // Test 5: Historical data
    print('📊 Test 5: Fetching 20-day historical data for SPY...');
    final historical = await service.fetchHistoricalPrices('SPY', days: 20);
    if (historical.isNotEmpty) {
      final sma20 = historical.map((p) => p.close).reduce((a, b) => a + b) / historical.length;
      print('✅ Fetched ${historical.length} days');
      print('   20-day SMA: \$${sma20.toStringAsFixed(2)}');
      print('   Latest close: \$${historical.last.close.toStringAsFixed(2)}');
    }
    print('');

    // Test 6: Rate limiting
    print('📊 Test 6: Rate limiter status...');
    print('✅ Remaining calls: ${service.remainingCalls}/60 per minute');
    print('   Real-time: ${service.isRealTime}\n');

    print('🎉 All tests passed!\n');
    print('Next steps:');
    print('1. Add TRADIER_API_KEY to your .env file');
    print('2. Uncomment provider in market_data_providers.dart');
    print('3. Integrate into cockpit controller');

  } catch (e) {
    print('❌ Error: $e');
  } finally {
    // Clean up
    await service.dispose();
  }
}

/// Run this as a standalone test
void main() async {
  const apiKey = 'YOUR_TRADIER_SANDBOX_KEY'; // Replace with your key

  if (apiKey == 'YOUR_TRADIER_SANDBOX_KEY') {
    print('❌ Error: Please set your Tradier sandbox API key');
    print('Get one at: https://developer.tradier.com/user/sign_up');
    return;
  }

  await testMarketData(apiKey);
}
