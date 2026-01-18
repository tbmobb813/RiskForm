import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
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
      lastTransition: newState != previousCycle.state ? DateTime.now() : null,
      updateLastTransition: newState != previousCycle.state,
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

    // Safely parse state (stored as int/num/string) and guard against out-of-range
    final rawState = data["state"];
    int? stateIndex;
    if (rawState is int) {
      stateIndex = rawState;
    } else if (rawState is num) {
      stateIndex = rawState.toInt();
    } else if (rawState is String) {
      stateIndex = int.tryParse(rawState);
    }

    WheelCycleState state;
    if (stateIndex == null || stateIndex < 0 || stateIndex >= WheelCycleState.values.length) {
      // Invalid or missing value in the DB; fall back to `idle` rather than throwing.
      // Use a lightweight log so developers can notice bad data during development.
      // Avoid import-heavy logging here — use print which is safe in all environments.
        developer.log('Invalid wheel cycle state from Firestore: $rawState; defaulting to idle.',
          name: 'wheel_cycle_service.getCycle');
      state = WheelCycleState.idle;
    } else {
      state = WheelCycleState.values[stateIndex];
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        if (v is Timestamp) return v.toDate();
        if (v is String) return DateTime.parse(v);
        if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
        if (v is Map && v.containsKey('_seconds')) {
          final s = v['_seconds'] as int;
          final ns = v['_nanoseconds'] as int? ?? 0;
          final ms = s * 1000 + (ns ~/ 1000000);
          return DateTime.fromMillisecondsSinceEpoch(ms);
        }
      } catch (_) {}
      return null;
    }

    return WheelCycle(
      state: _deserializeState(data["state"]),
      lastTransition: (data["lastTransition"] as Timestamp?)?.toDate(),
      cycleCount: data["cycleCount"] ?? 0,
    );
  }

  WheelCycleState _deserializeState(dynamic value) {
    if (value is String) {
      return WheelCycleState.values.firstWhere(
        (e) => e.name == value,
        orElse: () => WheelCycleState.idle,
      );
    }
    // Fallback for legacy integer-based storage with bounds checking
    if (value is int && value >= 0 && value < WheelCycleState.values.length) {
      return WheelCycleState.values[value];
    }
    return WheelCycleState.idle;
  }

  Future<void> saveCycle(String uid, WheelCycle cycle) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("wheel")
        .doc("cycle")
        .set({
      "state": cycle.state.name,
      "lastTransition": cycle.lastTransition,
      "cycleCount": cycle.cycleCount,
    });
  }
}