import '../models/wheel_cycle.dart';
import '../models/position.dart';

class WheelCycleController {
  WheelCycleState determineState({
    required WheelCycle previous,
    required List<Position> positions,
  }) {
    final hasCsp = positions.any(
      (p) => p.type == PositionType.csp && p.isOpen,
    );

    final hasShares = positions.any(
      (p) => p.type == PositionType.shares && p.quantity >= 100,
    );

    final hasCc = positions.any(
      (p) => p.type == PositionType.coveredCall && p.isOpen,
    );

    // If shares appear and the previous wheel state was a CSP open,
    // that's an assignment even if a transient CSP position is still present.
    if (hasShares && previous.state == WheelCycleState.cspOpen) {
      return WheelCycleState.assigned;
    }

    // If a CSP is currently open and the previous wheel state was idle,
    // prefer reporting the CSP as taking priority over shares. This mirrors
    // the UX expectation that an actively opened CSP is the primary state
    // when no prior wheel state indicates a run in progress.
    if (hasCsp && previous.state == WheelCycleState.idle) {
      return WheelCycleState.cspOpen;
    }

    // If shares are present, prefer shares/covered-call states next.
    if (hasShares && hasCc) return WheelCycleState.ccOpen;
    if (hasShares && !hasCc) return WheelCycleState.sharesOwned;

    // Fallback: if a CSP is present, report it.
    if (hasCsp) return WheelCycleState.cspOpen;

    // 5. Called away
    if (previous.state == WheelCycleState.ccOpen && !hasShares && !hasCc) {
      return WheelCycleState.calledAway;
    }

    // 6. Idle
    return WheelCycleState.idle;
  }
}