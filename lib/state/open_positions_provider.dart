import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/position.dart';
import '../services/data/position_repository.dart';

/// Live stream of the signed-in user's open positions. Emits an empty list
/// when nobody is signed in.
///
/// Filters on [Position.isOpen] client-side so the query needs no composite
/// Firestore index.
final openPositionsStreamProvider = StreamProvider<List<Position>>((ref) {
  final repo = ref.watch(positionRepositoryProvider);
  return repo.stream().map((all) => all.where((p) => p.isOpen).toList());
});
