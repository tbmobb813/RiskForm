import 'package:equatable/equatable.dart';
import '../models/trade_inputs.dart';
import '../models/payoff_result.dart';
import '../models/risk_result.dart';

class PlannerState extends Equatable {
  final String? strategyId;
  final String? strategyName;
  final String? strategyDescription;

  final TradeInputs? inputs;
  final PayoffResult? payoff;
  final RiskResult? risk;

  final String? notes;
  final List<String> tags;

  final bool isLoading;
  final String? errorMessage;

  const PlannerState({
    this.strategyId,
    this.strategyName,
    this.strategyDescription,
    this.inputs,
    this.payoff,
    this.risk,
    this.notes,
    this.tags = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  factory PlannerState.initial() => const PlannerState();

  PlannerState copyWith({
    String? strategyId,
    String? strategyName,
    String? strategyDescription,
    TradeInputs? inputs,
    PayoffResult? payoff,
    RiskResult? risk,
    String? notes,
    List<String>? tags,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlannerState(
      strategyId: strategyId ?? this.strategyId,
      strategyName: strategyName ?? this.strategyName,
      strategyDescription: strategyDescription ?? this.strategyDescription,
      inputs: inputs ?? this.inputs,
      payoff: payoff ?? this.payoff,
      risk: risk ?? this.risk,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        strategyId,
        strategyName,
        strategyDescription,
        inputs,
        payoff,
        risk,
        notes,
        tags,
        isLoading,
        errorMessage,
      ];
}