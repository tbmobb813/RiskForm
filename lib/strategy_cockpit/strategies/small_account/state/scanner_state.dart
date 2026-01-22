import 'package:flutter_riverpod/legacy.dart';
import '../models/scanner_filters.dart';
import 'package:riskform/strategy_cockpit/strategies/trading_strategy.dart';

class ScannerFiltersNotifier extends StateNotifier<ScannerFilters> {
  ScannerFiltersNotifier()
      : super(const ScannerFilters(
          maxPremium: 150,
          minDte: 30,
          maxDte: 60,
          maxBidAskSpread: 0.15,
          minOpenInterest: 20,
          minDelta: 0.20,
          maxDelta: 0.40,
        ));

  void setMaxPremium(double v) => state = state.copyWith(maxPremium: v);
  void setDteRange(int min, int max) => state = state.copyWith(minDte: min, maxDte: max);
  void setDeltaRange(double min, double max) => state = state.copyWith(minDelta: min, maxDelta: max);
  void setMinOpenInterest(int v) => state = state.copyWith(minOpenInterest: v);
  void setMaxBidAskSpread(double v) => state = state.copyWith(maxBidAskSpread: v);
}

final scannerFiltersProvider = StateNotifierProvider<ScannerFiltersNotifier, ScannerFilters>((ref) {
  return ScannerFiltersNotifier();
});

class ScannerResultsNotifier extends StateNotifier<List<TradingStrategy>> {
  ScannerResultsNotifier() : super([]);

  void setResults(List<TradingStrategy> r) => state = r;
  void clear() => state = [];
}

final scannerResultsProvider = StateNotifierProvider<ScannerResultsNotifier, List<TradingStrategy>>((ref) {
  return ScannerResultsNotifier();
});
