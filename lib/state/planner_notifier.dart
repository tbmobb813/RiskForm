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
import '../planner/models/planner_strategy_context.dart';

final plannerNotifierProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>(
  (ref) {
    final repository = ref.read(tradePlanRepositoryProvider);
    final payoffEngine = ref.read(payoffEngineProvider);
    final riskEngine = ref.read(riskEngineProvider);
    final executionService = ExecutionService();
    return PlannerNotifier(repository, payoffEngine, riskEngine, executionService);
  },
);

class PlannerNotifier extends StateNotifier<PlannerState> {
  final TradePlanRepository _repository;
  final PayoffEngine _payoffEngine;
  final RiskEngine _riskEngine;
    final ExecutionService? _executionService;

    PlannerNotifier(this._repository, this._payoffEngine, this._riskEngine, [this._executionService])
      : super(PlannerState.initial());

  // Strategy selection
  void setStrategy(String id, String name, String description) {
    state = PlannerState.initial().copyWith(
      strategyId: id,
      strategyName: name,
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
      final dte = inputs.expiration != null
          ? inputs.expiration!.difference(DateTime.now()).inDays
          : 30;
      final width = (inputs.shortStrike != null && inputs.longStrike != null)
          ? (inputs.shortStrike! - inputs.longStrike!).abs()
          : 20.0;
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
      final payoff = await _payoffEngine.compute(
        strategyId: state.strategyId!,
        inputs: state.inputs!,
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
      final risk = await _riskEngine.compute(
        strategyId: state.strategyId!,
        inputs: state.inputs!,
        payoff: state.payoff!,
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

      final executionPayload = state.inputs!.toJson();

      final request = StrategyExecutionRequest(
        strategyContext: ctx,
        execution: executionPayload,
        cycleId: null,
      );

      if (_executionService == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Execution service not available.');
        return false;
      }

      final result = await _executionService!.executeStrategyTrade(request);

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

  // Reset
  void reset() {
    state = PlannerState.initial();
  }
}