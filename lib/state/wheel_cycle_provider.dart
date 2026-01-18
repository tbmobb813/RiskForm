import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wheel_cycle.dart';
import '../services/firebase/wheel_cycle_service.dart';
import '../services/firebase/auth_service.dart';
import '../screens/dashboard/active_positions_section.dart';

final wheelCycleProvider = FutureProvider<WheelCycle>((ref) async {
  final auth = ref.read(authServiceProvider);
  final uid = auth.currentUserId;
  if (uid == null) throw Exception('No user logged in');

  final service = ref.read(wheelCycleServiceProvider);

  final positions = ref.watch(activePositionsProvider);

  final previous = await service.getCycle(uid) ?? WheelCycle(state: WheelCycleState.idle);

  return service.updateCycle(
    uid: uid,
    previous: previous,
    positions: positions,
  );
});
