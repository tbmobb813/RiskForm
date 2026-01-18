import 'package:flutter_riverpod/legacy.dart';
import '../models/trade_inputs.dart';
import '../models/trade_plan.dart';
import '../services/data/trade_plan_repository.dart';
import '../services/engines/payoff_engine.dart';
import 'planner_state.dart';
import '../services/engines/risk_engine.dart';

final plannerNotifierProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>(
  (ref) {
    final repository = ref.read(tradePlanRepositoryProvider);
    final payoffEngine = ref.read(payoffEngineProvider);
    final riskEngine = ref.read(riskEngineProvider);
    return PlannerNotifier(repository, payoffEngine, riskEngine);
  },
);

class PlannerNotifier extends StateNotifier<PlannerState> {
  final TradePlanRepository _repository;
  final PayoffEngine _payoffEngine;
  final RiskEngine _riskEngine;

  PlannerNotifier(this._repository, this._payoffEngine, this._riskEngine) : super(PlannerState.initial());

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
    if (state.inputs == null ||
        state.strategyId == null) {
      state = state.copyWith(errorMessage: "Missing trade inputs or strategy ID.");
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: call real engine
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
    if (state.payoff == null ||
        state.inputs == null ||
        state.strategyId == null) {
      state = state.copyWith(errorMessage: "Missing inputs, payoff or strategy ID.");
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: call real risk engine
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

  // Reset
  void reset() {
    state = PlannerState.initial();
  }
}