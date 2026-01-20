import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trade_inputs.dart';
import '../../models/payoff_result.dart';
import '../../models/risk_result.dart';
import '../../models/account_context.dart';
import '../../state/account_context_provider.dart';

/// Risk threshold constants for guardrail warnings.
class RiskThresholds {
  RiskThresholds._();

  /// Warning threshold: trade locks more than this % of account (moderate risk).
  static const double moderateRiskPercent = 5.0;

  /// Warning threshold: trade locks more than this % of account (high risk).
  static const double highRiskPercent = 10.0;
}

final riskEngineProvider = Provider<RiskEngine>((ref) {
  final accountAsync = ref.watch(accountContextProvider);

  return accountAsync.maybeWhen(
    data: (account) => RiskEngine(account),
    orElse: () => RiskEngine(const AccountContext(accountSize: 0, buyingPower: 0)),
  );
});

class RiskEngine {
  final AccountContext account;

  RiskEngine(this.account);

  Future<RiskResult> compute({
    required String strategyId,
    required TradeInputs inputs,
    required PayoffResult payoff,
  }) async {
    final capitalLocked = _capitalLocked(strategyId, inputs, payoff);
    final riskPercent = account.accountSize == 0
        ? 0.0
        : (capitalLocked / account.accountSize) * 100;

    final assignmentExposure = _assignmentExposure(strategyId);
    final warnings = _guardrails(
      strategyId: strategyId,
      riskPercent: riskPercent,
      capitalLocked: capitalLocked,
      assignmentExposure: assignmentExposure,
    );

    return RiskResult(
      riskPercentOfAccount: riskPercent,
      assignmentExposure: assignmentExposure,
      capitalLocked: capitalLocked,
      warnings: warnings,
    );
  }

  double _capitalLocked(
    String strategyId,
    TradeInputs inputs,
    PayoffResult payoff,
  ) {
    switch (strategyId) {
      case "csp":
        return payoff.capitalRequired;
      case "cc":
        return payoff.capitalRequired;
      case "credit_spread":
      case "debit_spread":
        return payoff.capitalRequired;
      case "long_call":
      case "long_put":
        return payoff.capitalRequired;
      case "protective_put":
      case "collar":
        return payoff.capitalRequired;
      default:
        return payoff.capitalRequired;
    }
  }

  bool _assignmentExposure(String strategyId) {
    switch (strategyId) {
      case "csp":
      case "cc":
      case "credit_spread":
      case "collar":
        return true;
      default:
        return false;
    }
  }

  List<String> _guardrails({
    required String strategyId,
    required double riskPercent,
    required double capitalLocked,
    required bool assignmentExposure,
  }) {
    final warnings = <String>[];

    if (riskPercent > RiskThresholds.moderateRiskPercent) {
      warnings.add("This trade locks more than ${RiskThresholds.moderateRiskPercent.toInt()}% of your account.");
    }
    if (riskPercent > RiskThresholds.highRiskPercent) {
      warnings.add("This trade locks more than ${RiskThresholds.highRiskPercent.toInt()}% of your account.");
    }
    if (assignmentExposure) {
      warnings.add("This strategy carries assignment exposure.");
    }
    if (capitalLocked > account.buyingPower) {
      warnings.add("Capital required exceeds your current buying power.");
    }

    return warnings;
  }
}