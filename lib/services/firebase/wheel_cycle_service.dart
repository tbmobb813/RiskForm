import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wheel_cycle.dart';
import '../../models/position.dart';
import '../../controllers/wheel_cycle_controller.dart';

final wheelCycleServiceProvider = Provider<WheelCycleService>((ref) {
  return WheelCycleService();
});

class WheelCycleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _controller = WheelCycleController();

  /// Update the wheel cycle for [uid]. If [previous] is provided it will be
  /// used as the prior state; otherwise the stored cycle will be loaded.
  Future<WheelCycle> updateCycle({
    required String uid,
    WheelCycle? previous,
    required List<Position> positions,
    bool persist = true,
  }) async {
    final previousCycle = previous ??
        await getCycle(uid) ??
        WheelCycle(
          state: WheelCycleState.idle,
          lastTransition: null,
          cycleCount: 0,
        );

    final newState = _controller.determineState(
      previous: previousCycle,
      positions: positions,
    );

    final updated = previousCycle.copyWith(
      state: newState,
      lastTransition: newState != previousCycle.state ? DateTime.now() : previousCycle.lastTransition,
      cycleCount: _incrementCycleCount(previousCycle, newState),
    );

    if (persist) {
      await saveCycle(uid, updated);
    }
    return updated;
  }

  int _incrementCycleCount(WheelCycle prev, WheelCycleState next) {
    if (prev.state == WheelCycleState.calledAway && next == WheelCycleState.idle) {
      return prev.cycleCount + 1;
    }
    return prev.cycleCount;
  }

  Future<WheelCycle?> getCycle(String uid) async {
    final doc = await _db
        .collection("users")
        .doc(uid)
        .collection("wheel")
        .doc("cycle")
        .get();
    
    if (!doc.exists) return null;

    final data = doc.data()!;
    return WheelCycle(
      state: WheelCycleState.values[data["state"]],
      lastTransition: (data["lastTransition"] as Timestamp?)?.toDate(),
      cycleCount: data["cycleCount"] ?? 0,
    );
  }

  Future<void> saveCycle(String uid, WheelCycle cycle) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("wheel")
        .doc("cycle")
        .set({
      "state": cycle.state.index,
      "lastTransition": cycle.lastTransition,
      "cycleCount": cycle.cycleCount,
    });
  }
}