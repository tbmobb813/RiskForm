import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_interface.dart';
import '../../models/position.dart';
import '../../exceptions/app_exceptions.dart';
import '../firebase/position_service.dart';
import '../firebase/auth_service.dart';

final positionRepositoryProvider = Provider<PositionRepository>((ref) {
  final service = ref.read(positionServiceProvider);
  final auth = ref.read(authServiceProvider);
  return PositionRepository(service, auth);
});

class PositionRepository implements RepositoryInterface<Position> {
  final PositionService _service;
  final AuthService _auth;

  /// In-memory cache of position IDs for save operations.
  /// Maps position identity (symbol + type + expiration) to document ID.
  final Map<String, String> _idCache = {};

  PositionRepository(this._service, this._auth);

  String _requireAuth() {
    final uid = _auth.currentUserId;
    if (uid == null) {
      throw AuthenticationException.notLoggedIn();
    }
    return uid;
  }

  @override
  Future<List<Position>> listAll() async {
    final uid = _auth.currentUserId;
    if (uid == null) return [];
    return _service.fetchPositions(uid);
  }

  /// Returns only open (active) positions.
  Future<List<Position>> listOpen() async {
    final uid = _auth.currentUserId;
    if (uid == null) return [];
    return _service.fetchOpenPositions(uid);
  }

  @override
  Future<Position?> getById(String id) async {
    final uid = _auth.currentUserId;
    if (uid == null) return null;
    return _service.fetchPosition(uid, id);
  }

  @override
  Future<void> save(Position item) async {
    final uid = _requireAuth();

    // Generate a cache key for this position
    final cacheKey = '${item.symbol}_${item.type.name}_${item.expiration.toIso8601String()}';

    // Check if we have a cached ID for this position
    final existingId = _idCache[cacheKey];

    if (existingId != null) {
      // Update existing position
      await _service.updatePosition(uid: uid, positionId: existingId, position: item);
    } else {
      // Create new position and cache the ID
      final newId = await _service.createPosition(uid: uid, position: item);
      _idCache[cacheKey] = newId;
    }
  }

  /// Closes a position by ID.
  Future<void> close(String positionId) async {
    final uid = _requireAuth();
    await _service.closePosition(uid: uid, positionId: positionId);
  }

  /// Deletes a position by ID.
  Future<void> delete(String positionId) async {
    final uid = _requireAuth();
    await _service.deletePosition(uid: uid, positionId: positionId);
  }

  /// Streams all positions.
  Stream<List<Position>> stream() {
    final uid = _auth.currentUserId;
    if (uid == null) return Stream.value([]);
    return _service.streamPositions(uid);
  }

  /// Streams only open positions.
  Stream<List<Position>> streamOpen() {
    final uid = _auth.currentUserId;
    if (uid == null) return Stream.value([]);
    return _service.streamOpenPositions(uid);
  }
}
