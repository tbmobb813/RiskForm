import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_interface.dart';
import '../../models/position.dart';

final positionRepositoryProvider = Provider<PositionRepository>((ref) {
  return PositionRepository();
});

class PositionRepository implements RepositoryInterface<Position> {
  @override
  Future<List<Position>> listAll() async => [];

  @override
  Future<Position?> getById(String id) async => null;

  @override
  Future<void> save(Position item) async {}
}
