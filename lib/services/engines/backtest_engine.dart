import 'package:flutter/foundation.dart';
import 'package:flutter_application_2/models/backtest/backtest_config.dart';
import 'package:flutter_application_2/models/backtest/backtest_result.dart';
import 'package:flutter_application_2/models/backtest/backtest_step.dart';
import 'package:flutter_application_2/models/backtest/wheel_sim_state.dart';
import 'package:flutter_application_2/models/wheel_cycle.dart';
import 'package:flutter_application_2/services/engines/wheel_helpers.dart';
import 'package:flutter_application_2/services/engines/option_pricing_engine.dart';
import 'dart:math';

// historical/regime classification helpers are now provided by the
// shared `riskform_core` package when needed; avoid unused imports here.
import 'package:flutter_application_2/models/analytics/market_regime.dart';
import 'package:flutter_application_2/models/analytics/regime_segment.dart';
import 'package:riskform_core/backtest/backtest_engine.dart' as core;

/// Pure, deterministic backtest engine scaffold.
class BacktestEngine {
  static const engineVersion = '1.0.0';

  // Using dynamic here keeps the scaffold decoupled from concrete engine
  // implementations; callers can pass real engines if available.
  final dynamic payoffEngine;
  final dynamic riskEngine;
  final dynamic metaStrategy;

  /// Required for deterministic option pricing. Ensures reproducible backtests.
  final OptionPricingEngine optionPricing;

  BacktestEngine({
    this.payoffEngine,
    this.riskEngine,
    this.metaStrategy,
    required this.optionPricing,
  });

  BacktestResult run(BacktestConfig config) {
    // Delegate to the shared core engine and convert the returned map
    // into the app's `BacktestResult` model.
    final coreEngine = core.CloudBacktestEngine();
    final resultMap = coreEngine.run(config.toMap());
    return BacktestResult.fromMap(Map<String, dynamic>.from(resultMap));
  }

  // ignore: unused_element
  MarketRegime? _dominantRegimeForCycle({
    required CycleStats cycle,
    required List<RegimeSegment> segments,
  }) {
    final cycleStart = cycle.startIndex ?? 0;
    final cycleEnd = cycle.endIndex ?? (cycle.startIndex ?? 0) + cycle.durationDays;

    MarketRegime? best;
    int bestOverlap = 0;

    for (final seg in segments) {
      final overlapStart = max(cycleStart, seg.startIndex);
      final overlapEnd = min(cycleEnd, seg.endIndex);
      final overlap = overlapEnd - overlapStart + 1;
      if (overlap > bestOverlap && overlap > 0) {
        bestOverlap = overlap;
        best = seg.regime;
      }
    }

    return best;
  }

  // --- Wheel simulation ---
  // ignore: unused_element
  WheelSimState _simulateWheelStep({
    required double price,
    required WheelSimState state,
    required BacktestConfig config,
    required List<String> notes,
  }) {
    // Operate on a copy to keep changes explicit
    final s = state.copy();
    final symbol = config.symbol;

    switch (s.cycle.state) {
      case WheelCycleState.idle:
        return _handleIdle(price, s, notes);
      case WheelCycleState.cspOpen:
        return _handleCspOpen(price, s, notes, symbol);
      case WheelCycleState.assigned:
        return _handleAssigned(price, s, notes);
      case WheelCycleState.sharesOwned:
        return _handleSharesOwned(price, s, notes);
      case WheelCycleState.ccOpen:
        return _handleCcOpen(price, s, notes, symbol);
      case WheelCycleState.calledAway:
        return _handleCalledAway(price, s, notes);
    }
  }

  WheelSimState _handleIdle(double price, WheelSimState state, List<String> notes) {
    // Sell CSP at ATM using Black-Scholes pricing
    final tYears = 30 / 365.0;
    final vol = 0.25;
    final strike = price;

    double premiumPerShare = optionPricing.priceEuropeanPut(
      spot: price,
      strike: strike,
      volatility: vol,
      timeToExpiryYears: tYears,
    );

    // Validate the computed premium to guard against edge cases
    if (premiumPerShare.isNaN || premiumPerShare.isInfinite || premiumPerShare < 0) {
      throw StateError(
        'Invalid option premium from pricing engine: $premiumPerShare '
        '(spot=$price, strike=$strike, vol=$vol, t=$tYears)',
      );
    }

    final premium = premiumPerShare * 100;
    state.capital += premium;

    // create in-sim option to track DTE and strike
    final dte = 30;
    state.csp = SimOption(
      strike: strike,
      dte: dte,
      isPut: true,
      isShort: true,
    );

    notes.add('Sold CSP @ ${strike.toStringAsFixed(2)}, DTE $dte, premium ${premium.toStringAsFixed(2)}');
    state.cycle = state.cycle.copyWith(state: WheelCycleState.cspOpen);
    return state;
  }

  WheelSimState _handleCspOpen(double price, WheelSimState state, List<String> notes, String symbol) {
    // Use the in-sim option if present
    final csp = state.csp;
    if (csp == null) {
      notes.add('CSP open but option missing; reverting to idle.');
      state.cycle = state.cycle.copyWith(state: WheelCycleState.idle);
      return state;
    }

    final strike = csp.strike;
    final isITM = price < strike;

    // Early-assignment heuristic (deterministic, rare)
    if (shouldEarlyAssign(
      symbol: symbol,
      strike: strike,
      dte: csp.dte,
      isPut: true,
      price: price,
    )) {
      // perform early assignment
      state.shares = 100;
      state.costBasis = strike;
      state.capital -= strike * 100;
      notes.add('CSP early-assigned @ ${strike.toStringAsFixed(2)}');
      state.cycle = state.cycle.copyWith(state: WheelCycleState.assigned);
      state.csp = null;
      return state;
    }

    if (csp.dte <= 0) {
      if (isITM) {
        // assignment at expiry
        state.shares = 100;
        state.costBasis = strike;
        state.capital -= strike * 100;
        notes.add('CSP expired ITM, assigned @ ${strike.toStringAsFixed(2)}');
        state.cycle = state.cycle.copyWith(state: WheelCycleState.assigned);
      } else {
        // expires worthless
        notes.add('CSP expired OTM, no assignment');
        state.cycle = state.cycle.copyWith(state: WheelCycleState.idle);
      }
      state.csp = null;
      return state;
    }

    notes.add('CSP open, DTE ${csp.dte}, spot ${price.toStringAsFixed(2)}');
    return state;
  }

  WheelSimState _handleAssigned(double price, WheelSimState state, List<String> notes) {
    notes.add('Shares confirmed at cost basis ${state.costBasis}');
    state.cycle = state.cycle.copyWith(state: WheelCycleState.sharesOwned);
    return state;
  }

  WheelSimState _handleSharesOwned(double price, WheelSimState state, List<String> notes) {
    // Sell covered call using Black-Scholes pricing
    final tYears = 30 / 365.0;
    final vol = 0.25;
    final strike = price * 1.02; // 2% OTM

    double premiumPerShare = optionPricing.priceEuropeanCall(
      spot: price,
      strike: strike,
      volatility: vol,
      timeToExpiryYears: tYears,
    );

    // Validate the computed premium to guard against edge cases
    if (premiumPerShare.isNaN || premiumPerShare.isInfinite || premiumPerShare < 0) {
      throw StateError(
        'Invalid option premium from pricing engine: $premiumPerShare '
        '(spot=$price, strike=$strike, vol=$vol, t=$tYears)',
      );
    }

    final premium = premiumPerShare * 100;
    state.capital += premium;

    final dte = 30;
    final strikeForOption = strike;
    state.cc = SimOption(
      strike: strikeForOption,
      dte: dte,
      isPut: false,
      isShort: true,
    );

    notes.add('Sold CC @ ${strikeForOption.toStringAsFixed(2)}, DTE $dte, premium ${premium.toStringAsFixed(2)}');
    state.cycle = state.cycle.copyWith(state: WheelCycleState.ccOpen);
    return state;
  }

  WheelSimState _handleCcOpen(double price, WheelSimState state, List<String> notes, String symbol) {
    final cc = state.cc;
    if (cc == null) {
      notes.add('CC open but option missing; keeping shares.');
      state.cycle = state.cycle.copyWith(state: WheelCycleState.sharesOwned);
      return state;
    }

    final strike = cc.strike;
    final isITM = price > strike;

    if (shouldEarlyAssign(
      symbol: symbol,
      strike: strike,
      dte: cc.dte,
      isPut: false,
      price: price,
    )) {
      // early called-away
      final proceeds = strike * 100;
      final gain = proceeds - (state.costBasis * 100);
      state.capital += proceeds;
      state.shares = 0;
      notes.add('CC early-called-away @ ${strike.toStringAsFixed(2)}, gain ${gain.toStringAsFixed(2)}');
      state.cycle = state.cycle.copyWith(
        state: WheelCycleState.calledAway,
        cycleCount: state.cycle.cycleCount + 1,
      );
      state.cc = null;
      return state;
    }

    if (cc.dte <= 0) {
      if (isITM) {
        final proceeds = cc.strike * 100;
        final gain = proceeds - (state.costBasis * 100);
        state.capital += proceeds;
        state.shares = 0;

        notes.add('CC expired ITM, called away @ ${cc.strike.toStringAsFixed(2)}, gain ${gain.toStringAsFixed(2)}');

        state.cycle = state.cycle.copyWith(
          state: WheelCycleState.calledAway,
          cycleCount: state.cycle.cycleCount + 1,
        );
      } else {
        notes.add('CC expired OTM, keep shares');
        state.cycle = state.cycle.copyWith(state: WheelCycleState.sharesOwned);
      }
      state.cc = null;
      return state;
    }

    notes.add('CC open, DTE ${cc.dte}, spot ${price.toStringAsFixed(2)}');
    return state;
  }

  WheelSimState _handleCalledAway(double price, WheelSimState state, List<String> notes) {
    notes.add('Cycle completed. Restarting wheel.');
    state.cycle = state.cycle.copyWith(state: WheelCycleState.idle);
    return state;
  }

  // ignore: unused_element
  BacktestStep _simulateStep({
    required double price,
    required double capital,
    required WheelCycle cycle,
    required BacktestConfig config,
    required List<String> notes,
  }) {
    // 1. Determine next action using the meta-strategy if available.
    String action = 'hold';
    String reason = 'no-op';

    try {
      if (metaStrategy != null) {
        final rec = metaStrategy.evaluate(
          account: _mockAccount(capital),
          positions: _mockPositions(cycle),
          wheel: cycle,
          riskProfile: _defaultRiskProfile(),
        );

        action = rec?.nextAction ?? action;
        reason = rec?.reason ?? reason;
      }
    } on NoSuchMethodError catch (e, st) {
      debugPrint('BacktestEngine: metaStrategy interface mismatch: $e\n$st');
      notes.add('metaStrategy error: $e');
    } on Exception catch (e, st) {
      debugPrint('BacktestEngine: metaStrategy evaluate failed: $e\n$st');
      notes.add('metaStrategy error: $e');
    }

    // 2. Apply payoff math via payoffEngine if present; fall back to zero gain.
    double gain = 0.0;
    try {
      if (payoffEngine != null) {
        final inputs = _mockInputs(price, action);
        final payoff = payoffEngine.calculatePayoff(inputs);
        gain = (payoff?.maxGain ?? 0.0) as double;
      }
    } on TypeError catch (e, st) {
      debugPrint('BacktestEngine: payoff calculation type error: $e\n$st');
      notes.add('payoff error: $e');
    } on Exception catch (e, st) {
      debugPrint('BacktestEngine: payoff calculation failed: $e\n$st');
      notes.add('payoff error: $e');
    }

    final newCapital = capital + gain;

    return BacktestStep(
      price: price,
      equity: newCapital,
      action: action,
      reason: reason,
    );
  }

  // ignore: unused_element
  WheelCycle _updateCycle(WheelCycle cycle, BacktestStep step) {
    // Placeholder: consumers should hook up `WheelCycleController` for
    // realistic lifecycle transitions. For now we keep cycle unchanged.
    return cycle.copyWith(
      state: cycle.state,
      cycleCount: cycle.cycleCount,
    );
  }

  // ignore: unused_element
  double _maxDrawdown(List<double> curve) {
    if (curve.isEmpty) return 0.0;
    double peak = curve.first;
    double maxDD = 0.0;

    for (final value in curve) {
      if (value > peak) peak = value;
      final dd = (peak - value) / peak;
      if (dd > maxDD) maxDD = dd;
    }

    return maxDD;
  }

  // --- Minimal internal mocks to keep engine self-contained for v1 ---
  // ignore: unused_element
  dynamic _mockAccount(double capital) => {'capital': capital};
  // ignore: unused_element
  List<dynamic> _mockPositions(WheelCycle cycle) => <dynamic>[];
  // ignore: unused_element
  dynamic _defaultRiskProfile() => {'risk': 'default'};
  // ignore: unused_element
  dynamic _mockInputs(double price, String action) => {'price': price, 'action': action};
}
