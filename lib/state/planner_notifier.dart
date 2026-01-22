import 'package:flutter_riverpod/legacy.dart';
import '../models/trade_inputs.dart';
import 'package:riskform/strategy_cockpit/analytics/regime_aware_planner_hints.dart' as planner_hints;
import 'package:riskform/strategy_cockpit/analytics/strategy_recommendations_engine.dart' as recs;
import '../models/trade_plan.dart';
import '../services/data/trade_plan_repository.dart';
import '../services/engines/payoff_engine.dart';
import 'planner_state.dart';
import '../services/engines/risk_engine.dart';
import '../execution/execution_service.dart';
import 'package:riskform/strategy_cockpit/strategies/trading_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/wheel_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/long_call_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/debit_spread_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/calendar_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/pmcc_strategy.dart';
import '../models/option_contract.dart';
import '../planner/models/planner_strategy_context.dart';
import 'package:riskform/engines/regime_providers.dart';
import 'package:riskform/engines/regime_engine.dart';
import 'package:riskform/services/regime_aware_planner_hints_providers.dart';
import 'package:riskform/services/regime_aware_planner_hints_service.dart';
import 'package:riskform/strategy_cockpit/sync_providers.dart';
import 'package:riskform/strategy_cockpit/live_sync_manager.dart';

final plannerNotifierProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>(
  (ref) {
    final repository = ref.read(tradePlanRepositoryProvider);
    final payoffEngine = ref.read(payoffEngineProvider);
    final riskEngine = ref.read(riskEngineProvider);
    final executionService = ExecutionService();
    final regimeEngine = ref.read(regimeEngineProvider);
    final hintsService = ref.read(regimeAwarePlannerHintsServiceProvider);
    final liveSync = ref.read(liveSyncManagerProvider);
    return PlannerNotifier(repository, payoffEngine, riskEngine, regimeEngine, hintsService, executionService, liveSync);
  },
);

class PlannerNotifier extends StateNotifier<PlannerState> {
  final TradePlanRepository _repository;
  final PayoffEngine _payoffEngine;
  final RiskEngine _riskEngine;
  final RegimeEngine? _regimeEngine;
    final RegimeAwarePlannerHintsService? _hintsService;
    final LiveSyncManager? _liveSyncManager;
    final ExecutionService? _executionService;
    PlannerNotifier(this._repository, this._payoffEngine, this._riskEngine, [this._regimeEngine, this._hintsService, this._executionService, this._liveSyncManager])
      : super(PlannerState.initial());

  // Strategy selection
  void setStrategy(String id, String name, String description, {String? symbol}) {
    state = PlannerState.initial().copyWith(
      strategyId: id,
      strategyName: name,
      strategySymbol: symbol,
      strategyDescription: description,
      clearError: true,
    );
  }

  // Inputs
  void updateInputs(TradeInputs inputs) {
    state = state.copyWith(
      inputs: inputs,
      payoff: null,
      risk: null,
      clearError: true,
    );
    // Compute planner hints with best-effort context derived from current planner state.
    try {
        final exp = inputs.expiration;
        final dte = exp != null ? exp.difference(DateTime.now()).inDays : 30;
        final short = inputs.shortStrike;
        final long = inputs.longStrike;
        final width = (short != null && long != null) ? (short - long).abs() : 20.0;
      final delta = 0.20; // placeholder: delta not captured by TradeInputs yet
      final size = inputs.sharesOwned ?? 1;

      final pstate = planner_hints.PlannerState(
        dte: dte,
        delta: delta,
        width: width,
        size: size,
        type: state.strategyId ?? 'unknown',
      );

      final constraints = recs.Constraints(maxRisk: 100, maxPositions: 5);
      // Attempt to fetch a live regime / hints for the strategy's symbol if available.
      final symbol = state.strategySymbol;
      if (_liveSyncManager != null && symbol != null) {
        // Use LiveSyncManager to orchestrate regime + hints and return a coherent result.
        // We only care about hintsBundle here.
        _liveSyncManager.refresh(symbol, recs.StrategyContext(
          healthScore: 50,
          pnlTrend: const [],
          disciplineTrend: const [],
          recentCycles: const [],
          constraints: constraints,
          currentRegime: 'sideways',
          drawdown: 0.0,
          backtestComparison: null,
        )).then((res) {
          state = state.copyWith(hintsBundle: res.hints);
        }).catchError((_) {});
      } else if (_hintsService != null) {
        final symbol = state.strategySymbol;
        _hintsService.generateHints(pstate, symbol: symbol).then((hints) {
          state = state.copyWith(hintsBundle: hints);
        }).catchError((_) {});
      } else {
        if (symbol != null) {
          _regimeEngine?.getRegime(symbol).then((regSnap) {
            final ctx = recs.StrategyContext(
              healthScore: 50,
              pnlTrend: const [],
              disciplineTrend: const [],
              recentCycles: const [],
              constraints: constraints,
              currentRegime: regSnap.trend,
              drawdown: 0.0,
              backtestComparison: null,
            );
            final hints = planner_hints.generateHints(pstate, ctx);
            state = state.copyWith(hintsBundle: hints);
          }).catchError((_) {
            final ctx = recs.StrategyContext(
              healthScore: 50,
              pnlTrend: const [],
              disciplineTrend: const [],
              recentCycles: const [],
              constraints: constraints,
              currentRegime: 'sideways',
              drawdown: 0.0,
              backtestComparison: null,
            );
            final hints = planner_hints.generateHints(pstate, ctx);
            state = state.copyWith(hintsBundle: hints);
          });
        } else {
          final ctx = recs.StrategyContext(
            healthScore: 50,
            pnlTrend: const [],
            disciplineTrend: const [],
            recentCycles: const [],
            constraints: constraints,
            currentRegime: 'sideways',
            drawdown: 0.0,
            backtestComparison: null,
          );

          final hints = planner_hints.generateHints(pstate, ctx);
          state = state.copyWith(hintsBundle: hints);
        }
      }
    } catch (_) {
      // non-fatal: do not block UI on hint generation errors
    }
  }

  // Notes
  void updateNotes(String notes) {
    state = state.copyWith(notes: notes, clearError: true);
  }

  // Tags
  void updateTags(List<String> tags) {
    state = state.copyWith(tags: List.unmodifiable(tags), clearError: true);
  }

  // Compute payoff (placeholder logic for now)
  Future<bool> computePayoff() async {
    if (state.inputs == null || state.strategyId == null) {
      state = state.copyWith(errorMessage: "Missing trade inputs or strategy ID.");
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final strategyId = state.strategyId!;
      final inputsLocal = state.inputs!;
      final payoff = await _payoffEngine.compute(
        strategyId: strategyId,
        inputs: inputsLocal,
      );

      state = state.copyWith(
        payoff: payoff,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Failed to compute payoff.",
      );
      return false;
    }
  }

  // Compute risk (placeholder logic for now)
  Future<bool> computeRisk() async {
    if (state.payoff == null || state.inputs == null || state.strategyId == null) {
      state = state.copyWith(errorMessage: "Missing inputs, payoff or strategy ID.");
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final strategyId = state.strategyId!;
      final inputsLocal = state.inputs!;
      final payoffLocal = state.payoff!;
      final risk = await _riskEngine.compute(
        strategyId: strategyId,
        inputs: inputsLocal,
        payoff: payoffLocal,
      );

      state = state.copyWith(
        risk: risk,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Failed to compute risk.",
      );
      return false;
    }
  }

  // Save plan
  Future<bool> savePlan() async {
    if (state.inputs == null ||
        state.payoff == null ||
        state.risk == null ||
        state.strategyId == null ||
        state.strategyName == null) {
      state = state.copyWith(errorMessage: "Missing required data.");
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final plan = TradePlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        strategyId: state.strategyId!,
        strategyName: state.strategyName!,
        inputs: state.inputs!,
        payoff: state.payoff!,
        risk: state.risk!,
        notes: state.notes ?? "",
        tags: state.tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Persist plan and update wheel cycle in one atomic flow.
      await _repository.savePlanAndUpdateWheel(plan);

      reset();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Failed to save plan.",
      );
      return false;
    }
  }

  // Execute trade via ExecutionService
  Future<bool> executeTrade() async {
    if (state.inputs == null || state.strategyId == null || state.strategyName == null) {
      state = state.copyWith(errorMessage: 'Missing required execution data.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Build a minimal PlannerStrategyContext from current planner state.
      final ctx = PlannerStrategyContext(
        strategyId: state.strategyId!,
        strategyName: state.strategyName!,
        state: 'active',
        tags: state.tags,
        constraintsSummary: null,
        constraints: {},
        currentRegime: null,
        disciplineFlags: [],
        updatedAt: DateTime.now(),
      );

      final raw = state.inputs!.toJson();

      // Enrich execution payload with fields expected by analytics
      final now = DateTime.now();
      final premium = (raw['premiumReceived'] as num?)?.toDouble() ?? (raw['premiumPaid'] as num?)?.toDouble() ?? (raw['netCredit'] as num?)?.toDouble() ?? (raw['netDebit'] as num?)?.toDouble() ?? 0.0;
      final qty = (raw['sharesOwned'] as num?)?.toInt() ?? 1;
      final expiry = raw['expiration'] ?? raw['expiry'];
      final symbol = state.strategySymbol ?? ctx.strategyName;
      final type = (premium > 0) ? 'SELL' : 'BUY';

      final executionPayload = Map<String, dynamic>.from(raw)
        ..['timestamp'] = now.toIso8601String()
        ..['symbol'] = symbol
        ..['type'] = type
        ..['qty'] = qty
        ..['premium'] = premium
        ..['expiry'] = expiry;

      // Attach strategy metadata (explanation) when available
      final strategy = _strategyFromState();
      if (strategy != null) {
        final expl = strategy.explain();
        executionPayload['strategyMeta'] = {
          'id': strategy.id,
          'label': strategy.label,
          'explanation': {
            'summary': expl.summary,
            'pros': expl.pros,
            'cons': expl.cons,
            'idealConditions': expl.idealConditions,
            'risks': expl.risks,
          }
        };
      }

      final request = StrategyExecutionRequest(
        strategyContext: ctx,
        execution: executionPayload,
        cycleId: null,
      );

      if (_executionService == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Execution service not available.');
        return false;
      }

      final exec = _executionService;
      final result = await exec.executeStrategyTrade(request);

      if (!result.success) {
        state = state.copyWith(isLoading: false, errorMessage: result.errorMessage);
        return false;
      }

      // On success, clear planner inputs and keep a short success indicator
      reset();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Execution failed: $e');
      return false;
    }
  }

  // Map current planner state -> TradingStrategy (lightweight, deterministic)
  TradingStrategy? _strategyFromState() {
    try {
      final id = state.strategyId;
      final inputsLocal = state.inputs;
      if (id == null || inputsLocal == null) return null;

      final expiry = inputsLocal.expiration ?? DateTime.now().add(const Duration(days: 30));

      switch (id) {
        case 'wheel-cycle':
          final put = OptionContract(
            id: 'PUT1',
            strike: inputsLocal.strike ?? inputsLocal.shortStrike ?? (inputsLocal.underlyingPrice ?? 0.0),
            premium: inputsLocal.premiumReceived ?? inputsLocal.netCredit ?? 0.0,
            expiry: expiry,
            type: 'put',
          );

          OptionContract? call;
          if ((inputsLocal.sharesOwned ?? 0) >= 100 && (inputsLocal.shortStrike != null)) {
            call = OptionContract(
              id: 'CALL1',
              strike: inputsLocal.shortStrike ?? (inputsLocal.underlyingPrice ?? 0.0),
              premium: inputsLocal.premiumReceived ?? inputsLocal.netCredit ?? 0.0,
              expiry: expiry,
              type: 'call',
            );
          }

          return WheelStrategy(
            id: 'wheel-cycle',
            label: 'Wheel',
            putContract: put,
            callContract: call,
            shareQuantity: inputsLocal.sharesOwned ?? 100,
            cycle: null,
          );

        case 'long_call':
          final contract = OptionContract(
            id: 'LC',
            strike: inputsLocal.strike ?? 0.0,
            premium: inputsLocal.premiumPaid ?? inputsLocal.netDebit ?? 0.0,
            expiry: expiry,
            type: 'call',
          );
          return LongCallStrategy(contract);

        case 'debit_spread':
          final long = OptionContract(
            id: 'L',
            strike: inputsLocal.longStrike ?? 0.0,
            premium: 0.0,
            expiry: expiry,
            type: 'call',
          );
          final short = OptionContract(
            id: 'S',
            strike: inputsLocal.shortStrike ?? 0.0,
            premium: 0.0,
            expiry: expiry,
            type: 'call',
          );
          return DebitSpreadStrategy(longLeg: long, shortLeg: short);

        case 'calendar':
          if (inputsLocal.longStrike != null && inputsLocal.shortStrike != null) {
            final long = OptionContract(
              id: 'CAL_LONG',
              strike: inputsLocal.longStrike!,
              premium: 0.0,
              expiry: expiry,
              type: 'call',
            );
            final short = OptionContract(
              id: 'CAL_SHORT',
              strike: inputsLocal.shortStrike!,
              premium: 0.0,
              expiry: expiry,
              type: 'call',
            );
            return CalendarStrategy(longLeg: long, shortLeg: short);
          }
          return null;

        case 'pmcc':
          if (inputsLocal.shortStrike != null) {
            final call = OptionContract(
              id: 'PMCC_CALL',
              strike: inputsLocal.shortStrike!,
              premium: inputsLocal.premiumReceived ?? 0.0,
              expiry: expiry,
              type: 'call',
            );
            return PMCCStrategy(callContract: call, shareQuantity: inputsLocal.sharesOwned ?? 100, costBasis: inputsLocal.costBasis ?? 0.0);
          }
          return null;

        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  // Reset
  void reset() {
    state = PlannerState.initial();
  }

  /// Recompute planner hints using lightweight slider-derived overrides.
  /// This does not persist inputs; it computes a best-effort PlannerState
  /// from the current planner state and the provided numeric overrides,
  /// then updates `state.hintsBundle` so the UI can react in real time.
  void computeHintsFromSliders({double? delta, double? width, int? dte}) {
    try {
      final inputs = state.inputs;

        final exp = inputs?.expiration;
        final computedDte = dte ?? (exp != null ? exp.difference(DateTime.now()).inDays : 30);

        final short = inputs?.shortStrike;
        final long = inputs?.longStrike;
        final computedWidth = width ?? ((short != null && long != null) ? (short - long).abs() : 20.0);

      final computedDelta = delta ?? 0.20;

      final pstate = planner_hints.PlannerState(
        dte: computedDte,
        delta: computedDelta,
        width: computedWidth,
        size: inputs?.sharesOwned ?? 1,
        type: state.strategyId ?? 'unknown',
      );

      final constraints = recs.Constraints(maxRisk: 100, maxPositions: 5);
      final symbol = state.strategySymbol;
      final lsm = _liveSyncManager;
      if (lsm != null && symbol != null) {
        lsm.refresh(symbol, recs.StrategyContext(
          healthScore: 50,
          pnlTrend: const [],
          disciplineTrend: const [],
          recentCycles: const [],
          constraints: constraints,
          currentRegime: 'sideways',
          drawdown: 0.0,
          backtestComparison: null,
        )).then((res) {
          state = state.copyWith(hintsBundle: res.hints);
        }).catchError((_) {});
      } else if (_hintsService != null) {
        final symbol = state.strategySymbol;
        final hs = _hintsService;
        hs.generateHints(pstate, symbol: symbol).then((hints) {
          state = state.copyWith(hintsBundle: hints);
        }).catchError((_) {});
      } else {
        if (symbol != null) {
          _regimeEngine?.getRegime(symbol).then((regSnap) {
            final ctx = recs.StrategyContext(
              healthScore: 50,
              pnlTrend: const [],
              disciplineTrend: const [],
              recentCycles: const [],
              constraints: constraints,
              currentRegime: regSnap.trend,
              drawdown: 0.0,
              backtestComparison: null,
            );
            final hints = planner_hints.generateHints(pstate, ctx);
            state = state.copyWith(hintsBundle: hints);
          }).catchError((_) {
            final ctx = recs.StrategyContext(
              healthScore: 50,
              pnlTrend: const [],
              disciplineTrend: const [],
              recentCycles: const [],
              constraints: constraints,
              currentRegime: 'sideways',
              drawdown: 0.0,
              backtestComparison: null,
            );
            final hints = planner_hints.generateHints(pstate, ctx);
            state = state.copyWith(hintsBundle: hints);
          });
        } else {
          final ctx = recs.StrategyContext(
            healthScore: 50,
            pnlTrend: const [],
            disciplineTrend: const [],
            recentCycles: const [],
            constraints: constraints,
            currentRegime: 'sideways',
            drawdown: 0.0,
            backtestComparison: null,
          );

          final hints = planner_hints.generateHints(pstate, ctx);
          state = state.copyWith(hintsBundle: hints);
        }
      }
    } catch (_) {
      // swallow errors to avoid breaking UI
    }
  }

  /// Update the planner's `inputs` with numeric overrides derived from sliders
  /// (delta, width, dte) and recompute hints. This persists the slider values
  /// into `state.inputs` so subsequent save/execute actions include them.
  void updateInputsFromSliders({double? delta, double? width, int? dte}) {
    final existing = state.inputs;

    DateTime? newExpiration = existing?.expiration;
    if (dte != null) {
      newExpiration = DateTime.now().add(Duration(days: dte));
    }

    final newInputs = TradeInputs(
      strike: existing?.strike,
      longStrike: existing?.longStrike,
      shortStrike: existing?.shortStrike,
      premiumPaid: existing?.premiumPaid,
      premiumReceived: existing?.premiumReceived,
      netDebit: existing?.netDebit,
      netCredit: existing?.netCredit,
      underlyingPrice: existing?.underlyingPrice,
      costBasis: existing?.costBasis,
      sharesOwned: existing?.sharesOwned,
      expiration: newExpiration,
      delta: delta ?? existing?.delta,
      width: width ?? existing?.width,
    );

    state = state.copyWith(inputs: newInputs);

    // Recompute hints using the updated numeric values
    computeHintsFromSliders(delta: delta, width: width, dte: dte);
  }
}