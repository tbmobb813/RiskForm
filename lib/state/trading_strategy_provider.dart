import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../strategy_cockpit/strategies/trading_strategy.dart';
import '../strategy_cockpit/strategies/wheel_strategy.dart';
import '../strategy_cockpit/strategies/long_call_strategy.dart';
import '../strategy_cockpit/strategies/debit_spread_strategy.dart';
import '../strategy_cockpit/strategies/calendar_strategy.dart';
import '../strategy_cockpit/strategies/pmcc_strategy.dart';
import '../models/option_contract.dart';
import 'planner_notifier.dart';

final tradingStrategyProvider = Provider<TradingStrategy?>((ref) {
  try {
    final state = ref.watch(plannerNotifierProvider);
    final id = state.strategyId;
    final inputs = state.inputs;
    if (id == null || inputs == null) return null;

    // Helper to produce an expiry date
    final expiry = inputs.expiration ?? DateTime.now().add(const Duration(days: 30));

    switch (id) {
      case 'wheel-cycle':
        final put = OptionContract(
          id: 'PUT1',
          strike: inputs.strike ?? inputs.shortStrike ?? (inputs.underlyingPrice ?? 0.0),
          premium: inputs.premiumReceived ?? inputs.netCredit ?? 0.0,
          expiry: expiry,
          type: 'put',
        );

        OptionContract? call;
        if ((inputs.sharesOwned ?? 0) >= 100 && (inputs.shortStrike != null)) {
          call = OptionContract(
            id: 'CALL1',
            strike: inputs.shortStrike ?? (inputs.underlyingPrice ?? 0.0),
            premium: inputs.premiumReceived ?? inputs.netCredit ?? 0.0,
            expiry: expiry,
            type: 'call',
          );
        }

        return WheelStrategy(
          id: 'wheel-cycle',
          label: 'Wheel',
          putContract: put,
          callContract: call,
          shareQuantity: inputs.sharesOwned ?? 100,
        );

      case 'calendar':
        if (inputs.longStrike != null && inputs.shortStrike != null) {
          final long = OptionContract(
            id: 'CAL_LONG',
            strike: inputs.longStrike!,
            premium: 0.0,
            expiry: expiry,
            type: 'call',
          );
          final short = OptionContract(
            id: 'CAL_SHORT',
            strike: inputs.shortStrike!,
            premium: 0.0,
            expiry: expiry,
            type: 'call',
          );
          return CalendarStrategy(longLeg: long, shortLeg: short);
        }

        return null;

      case 'pmcc':
        if (inputs.shortStrike != null) {
          final call = OptionContract(
            id: 'PMCC_CALL',
            strike: inputs.shortStrike!,
            premium: inputs.premiumReceived ?? 0.0,
            expiry: expiry,
            type: 'call',
          );
          return PMCCStrategy(callContract: call, shareQuantity: inputs.sharesOwned ?? 100, costBasis: inputs.costBasis ?? 0.0);
        }

        return null;

      case 'long_call':
        final contract = OptionContract(
          id: 'LC',
          strike: inputs.strike ?? 0.0,
          premium: inputs.premiumPaid ?? inputs.netDebit ?? 0.0,
          expiry: expiry,
          type: 'call',
        );
        return LongCallStrategy(contract);

      case 'debit_spread':
        final long = OptionContract(
          id: 'L',
          strike: inputs.longStrike ?? 0.0,
          premium: 0.0,
          expiry: expiry,
          type: 'call',
        );
        final short = OptionContract(
          id: 'S',
          strike: inputs.shortStrike ?? 0.0,
          premium: 0.0,
          expiry: expiry,
          type: 'call',
        );
        return DebitSpreadStrategy(longLeg: long, shortLeg: short);

      default:
        return null;
    }
  } catch (_) {
    return null;
  }
});
