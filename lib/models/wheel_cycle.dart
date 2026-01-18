enum WheelCycleState {
  idle,
  cspOpen,
  assigned,
  sharesOwned,
  ccOpen,
  calledAway,
}

class WheelCycle {
  final WheelCycleState state;
  final DateTime? lastTransition;
  final int cycleCount;

  WheelCycle({
    required this.state,
    this.lastTransition,
    this.cycleCount = 0,
  });

  WheelCycle copyWith({
    WheelCycleState? state,
    DateTime? lastTransition,
    int? cycleCount,
  }) {
    return WheelCycle(
      state: state ?? this.state,
      lastTransition: lastTransition ?? this.lastTransition,
      cycleCount: cycleCount ?? this.cycleCount,
    );
  }
}