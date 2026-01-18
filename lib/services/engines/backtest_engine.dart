import 'package:flutter/foundation.dart';
import 'package:flutter_application_2/models/backtest/backtest_config.dart';
import 'package:flutter_application_2/models/backtest/backtest_result.dart';
import 'package:flutter_application_2/models/backtest/backtest_step.dart';
import 'package:flutter_application_2/models/wheel_cycle.dart';

/// Pure, deterministic backtest engine scaffold.
class BacktestEngine {
  // Using dynamic here keeps the scaffold decoupled from concrete engine
  // implementations; callers can pass real engines if available.
  final dynamic payoffEngine;
  final dynamic riskEngine;
  final dynamic metaStrategy;

  BacktestEngine({
    this.payoffEngine,
    this.riskEngine,
    this.metaStrategy,
  });

  BacktestResult run(BacktestConfig config) {
    double capital = config.startingCapital;
    final equityCurve = <double>[];
    final notes = <String>[];

    WheelCycle cycle = WheelCycle(state: WheelCycleState.idle);
    List<BacktestStep> steps = [];

    for (final price in config.pricePath) {
      final step = _simulateStep(
        price: price,
        capital: capital,
        cycle: cycle,
        config: config,
        notes: notes,
      );

      capital = step.equity;
      equityCurve.add(capital);
      steps.add(step);

      // update wheel state (placeholder)
      cycle = _updateCycle(cycle, step);
    }

    return BacktestResult(
      equityCurve: equityCurve,
      maxDrawdown: _maxDrawdown(equityCurve),
      totalReturn: (capital - config.startingCapital) / config.startingCapital,
      cyclesCompleted: cycle.cycleCount,
      notes: notes,
    );
  }

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
    } catch (e, st) {
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
    } catch (e, st) {
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

  WheelCycle _updateCycle(WheelCycle cycle, BacktestStep step) {
    // Placeholder: consumers should hook up `WheelCycleController` for
    // realistic lifecycle transitions. For now we keep cycle unchanged.
    return cycle.copyWith(
      state: cycle.state,
      cycleCount: cycle.cycleCount,
    );
  }

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
  dynamic _mockAccount(double capital) => {'capital': capital};
  List<dynamic> _mockPositions(WheelCycle cycle) => <dynamic>[];
  dynamic _defaultRiskProfile() => {'risk': 'default'};
  dynamic _mockInputs(double price, String action) => {'price': price, 'action': action};
}
