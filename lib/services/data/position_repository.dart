import 'repository_interface.dart';
import '../../models/position.dart';

class PositionRepository implements RepositoryInterface<Position> {
  @override
  Future<List<Position>> listAll() async => [];

  @override
  Future<Position?> getById(String id) async => null;

  @override
  Future<void> save(Position item) async {}
}
