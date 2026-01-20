import 'package:flutter_riverpod/legacy.dart';
import '../models/trade_inputs.dart';
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
  final ExecutionService _executionService;

  PlannerNotifier(this._repository, this._payoffEngine, this._riskEngine, this._executionService)
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

      final result = await _executionService.executeStrategyTrade(request);

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