import 'package:flutter/foundation.dart';

import 'package:riskform/strategy_cockpit/strategies/trading_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/long_call_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/long_put_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/leg.dart';
import 'package:riskform/strategy_cockpit/strategies/payoff_point.dart';
import 'package:riskform/models/option_contract.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/models/scanner_filters.dart';

/// Minimal option chain types to avoid coupling to specific data provider.
class OptionChain {
  final List<OptionExpiry> expirations;
  OptionChain({required this.expirations});
}

class OptionExpiry {
  final DateTime expiry;
  final int dte;
  final List<ChainOption> calls;
  final List<ChainOption> puts;
  OptionExpiry({required this.expiry, required this.dte, required this.calls, required this.puts});
}

class ChainOption {
  final OptionContract contract;
  final double bid;
  final double ask;
  final int volume;
  final int openInterest;
  final double delta;

  double get premium => (bid + ask) / 2.0;
  double get bidAskSpread => (ask - bid).abs();

  ChainOption({required this.contract, required this.bid, required this.ask, required this.volume, required this.openInterest, required this.delta});
}

/// Abstraction for fetching chains from existing services.
abstract class OptionsChainService {
  Future<OptionChain> fetchChain(String ticker);
}

class CheapOptionsScanner {
  final OptionsChainService chainService;

  CheapOptionsScanner(this.chainService);

  Future<List<TradingStrategy>> scan({
    required String ticker,
    required ScannerFilters filters,
  }) async {
    final chain = await chainService.fetchChain(ticker);
    final List<TradingStrategy> results = [];

    for (final expiry in chain.expirations) {
      final dte = expiry.dte;
      if (dte < filters.minDte || dte > filters.maxDte) continue;

      for (final contract in expiry.calls) {
        if (_matchesFilters(contract, filters)) {
          // Wrap as LongCallStrategy
          results.add(LongCallStrategy(contract.contract));
        }
      }

      for (final contract in expiry.puts) {
        if (_matchesFilters(contract, filters)) {
          // Wrap as LongPutStrategy (must exist)
          results.add(LongPutStrategy(contract.contract));
        }
      }
    }

    return results;
  }

  bool _matchesFilters(ChainOption c, ScannerFilters f) {
    if (c.premium > f.maxPremium) return false;
    if (c.bidAskSpread > f.maxBidAskSpread) return false;
    if (c.openInterest < f.minOpenInterest) return false;

    if (f.minDelta != null && c.delta < f.minDelta!) return false;
    if (f.maxDelta != null && c.delta > f.maxDelta!) return false;

    return true;
  }
}
