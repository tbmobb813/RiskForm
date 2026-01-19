import '../models/account_snapshot.dart';
import '../models/position.dart';
import '../models/wheel_cycle.dart';
import '../models/strategy_recommendation.dart';
import '../models/risk_profile.dart';
import 'wheel_cycle_controller.dart';

class MetaStrategyController {
  final WheelCycleController _wheelCycleController;

  MetaStrategyController() : _wheelCycleController = WheelCycleController();

  StrategyRecommendation evaluate({
    required AccountSnapshot account,
    required List<Position> positions,
    required WheelCycle wheel,
    required RiskProfile riskProfile,
  }) {
    // Use WheelCycleController to determine state instead of duplicating logic
    final cycleState = _wheelCycleController.determineState(
      previous: wheel,
      positions: positions,
    );

    final nextAction = _determineNextAction(
      cycleState: cycleState,
      account: account,
      positions: positions,
      riskProfile: riskProfile,
    );

    return StrategyRecommendation(
      strategyId: 'wheel-cycle',
      strategyName: 'Wheel Cycle Strategy',
      action: nextAction.action,
      reason: nextAction.reason,
      wheelState: cycleState,
    );
  }

  WheelCycleState _determineWheelState(
    List<Position> positions,
    WheelCycle wheel,
  ) {
    final hasOpenCsp = positions.any((p) => p.type == PositionType.csp && p.isOpen);
    final hasShares = positions.any((p) => p.type == PositionType.shares && p.quantity >= 100);
    final hasOpenCc = positions.any((p) => p.type == PositionType.coveredCall && p.isOpen);

    // Priority order (mirror WheelCycleController rules where history matters)
    // Assigned: previously a CSP was open and now shares appear — check first
    // so we don't hide an assignment when the CSP position still appears in
    // the position list (e.g., transient state where both CSP and shares
    // coexist). This keeps behavior consistent with WheelCycleController.
    if (hasShares && wheel.state == WheelCycleState.cspOpen) {
      return WheelCycleState.assigned;
    }

    // If shares are present, prefer shares/covered-call states before
    // reporting an open CSP. This prevents transient CSP records from
    // shadowing the fact that shares are already held.
    if (hasShares && hasOpenCc) return WheelCycleState.ccOpen;
    if (hasShares && !hasOpenCc) return WheelCycleState.sharesOwned;

    if (hasOpenCsp) return WheelCycleState.cspOpen;

    // Called away if previously in ccOpen and now no shares/cc
    if (wheel.state == WheelCycleState.ccOpen && !hasShares && !hasOpenCc) {
      return WheelCycleState.calledAway;
    }

    return WheelCycleState.idle;
  }

  _NextActionResult _determineNextAction({
    required WheelCycleState cycleState,
    required AccountSnapshot account,
    required List<Position> positions,
    required RiskProfile riskProfile,
  }) {
    switch (cycleState) {
      case WheelCycleState.idle:
        return _nextActionForIdle(account, riskProfile);
      case WheelCycleState.cspOpen:
        return _nextActionForCspOpen();
      case WheelCycleState.assigned:
        return _nextActionForAssigned();
      case WheelCycleState.sharesOwned:
        return _nextActionForSharesOwned();
      case WheelCycleState.ccOpen:
        return _nextActionForCcOpen();
      case WheelCycleState.calledAway:
        return _nextActionForCalledAway(account, riskProfile);
    }
  }

  bool _hasSufficientBuyingPower(
    AccountSnapshot account,
    RiskProfile riskProfile,
  ) {
    final minRequired = account.accountSize * (riskProfile.maxRiskPerTradePercent / 100);
    return account.buyingPower >= minRequired;
  }

  _NextActionResult _nextActionForIdle(
    AccountSnapshot account,
    RiskProfile riskProfile,
  ) {
    if (!_hasSufficientBuyingPower(account, riskProfile)) {
      return _NextActionResult(
        action: "No new trade",
        reason: "Buying power is below your per-trade risk threshold.",
      );
    }
    return _NextActionResult(
      action: "Sell Cash-Secured Put",
      reason: "No active wheel positions and sufficient buying power.",
    );
  }

  _NextActionResult _nextActionForCspOpen() {
    return _NextActionResult(
      action: "Manage Open CSP",
      reason: "You have a cash-secured put open. Manage or roll it.",
    );
  }

  _NextActionResult _nextActionForAssigned() {
    return _NextActionResult(
      action: "Review Assignment",
      reason: "You were assigned — confirm shares and prepare to sell a covered call.",
    );
  }

  _NextActionResult _nextActionForSharesOwned() {
    return _NextActionResult(
      action: "Sell Covered Call",
      reason: "You own ≥100 shares with no active covered call.",
    );
  }

  _NextActionResult _nextActionForCcOpen() {
    return _NextActionResult(
      action: "Manage Covered Call",
      reason: "You have an active covered call. Manage or roll as needed.",
    );
  }

  _NextActionResult _nextActionForCalledAway(
    AccountSnapshot account,
    RiskProfile riskProfile,
  ) {
    if (!_hasSufficientBuyingPower(account, riskProfile)) {
      return _NextActionResult(
        action: "Wait",
        reason: "Shares were called away, but buying power is below your risk threshold.",
      );
    }
    return _NextActionResult(
      action: "Restart Wheel with CSP",
      reason: "Shares were called away — you can restart the wheel with a new CSP.",
    );
  }
}

class _NextActionResult {
  final String action;
  final String reason;
  _NextActionResult({required this.action, required this.reason});
}