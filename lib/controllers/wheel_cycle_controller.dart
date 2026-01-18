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

    // 1. CSP open
    if (hasCsp) return WheelCycleState.cspOpen;

    // 2. Assigned
    if (!hasCsp && hasShares && previous.state == WheelCycleState.cspOpen) {
      return WheelCycleState.assigned;
    }

    // 3. Shares owned
    if (hasShares && !hasCc) return WheelCycleState.sharesOwned;

    // 4. CC open
    if (hasShares && hasCc) return WheelCycleState.ccOpen;

    // 5. Called away
    if (previous.state == WheelCycleState.ccOpen && !hasShares && !hasCc) {
      return WheelCycleState.calledAway;
    }

    // 6. Idle
    return WheelCycleState.idle;
  }
}