import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'market_data_providers.dart';
import 'market_data_models.dart';

/// Provides the latest price for a given ticker symbol.
final currentPriceProvider = FutureProvider.family<double?, String>((ref, symbol) async {
  if (symbol.isEmpty) return null;

  final market = ref.read(marketDataServiceProvider);
  try {
    final MarketPriceSnapshot snap = await market.getPrice(symbol);
    return snap.last;
  } catch (_) {
    return null;
  }
});
