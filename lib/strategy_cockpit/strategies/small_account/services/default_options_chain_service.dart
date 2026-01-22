import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cheap_options_scanner.dart';
import 'package:riskform/models/option_contract.dart';

class DefaultOptionsChainService implements OptionsChainService {
  DefaultOptionsChainService();

  @override
  Future<OptionChain> fetchChain(String ticker) async {
    // Return a small synthetic chain for UI/demo purposes.
    final now = DateTime.now();
    final expiries = <OptionExpiry>[];
    for (final days in [30, 60, 90]) {
      final expiryDate = now.add(Duration(days: days));
      final dte = days;
      final strikes = [90.0, 95.0, 100.0, 105.0, 110.0];
      final calls = <ChainOption>[];
      final puts = <ChainOption>[];
      final rnd = Random(100 + days);

      for (final s in strikes) {
        final bid = max(0.01, (s - 95) / 100 + rnd.nextDouble());
        final ask = bid + 0.5 + rnd.nextDouble() * 0.5;
        final vol = 100 + rnd.nextInt(500);
        final oi = 10 + rnd.nextInt(200);
        final deltaCall = ((s - 100) / 20).clamp(-1.0, 1.0).toDouble() + 0.5;
        final deltaPut = -deltaCall;

        final callContract = OptionContract(
          id: 'C_${days}_$s',
          strike: s,
          premium: (bid + ask) / 2.0,
          expiry: expiryDate,
          type: 'call',
        );

        final putContract = OptionContract(
          id: 'P_${days}_$s',
          strike: s,
          premium: (bid + ask) / 2.0,
          expiry: expiryDate,
          type: 'put',
        );

        calls.add(ChainOption(contract: callContract, bid: bid, ask: ask, volume: vol, openInterest: oi, delta: deltaCall));
        puts.add(ChainOption(contract: putContract, bid: bid, ask: ask, volume: vol, openInterest: oi, delta: deltaPut));
      }

      expiries.add(OptionExpiry(expiry: expiryDate, dte: dte, calls: calls, puts: puts));
    }

    return OptionChain(expirations: expiries);
  }
}

final defaultOptionsChainServiceProvider = Provider<OptionsChainService>((ref) {
  return DefaultOptionsChainService();
});
