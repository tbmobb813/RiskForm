import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/position.dart';
import '../../exceptions/app_exceptions.dart';

final positionServiceProvider = Provider<PositionService>((ref) => PositionService());

class PositionService {
  final FirebaseFirestore _db;

  PositionService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _positionsCollection(String uid) {
    return _db.collection('users').doc(uid).collection('positions');
  }

  /// Fetches all positions for a user.
  Future<List<Position>> fetchPositions(String uid) async {
    try {
      final snapshot = await _positionsCollection(uid)
          .orderBy('expiration')
          .get();

      return snapshot.docs.map((doc) {
        // make a new map that includes the Firestore document ID so the model can capture it
        final data = {...doc.data(), 'id': doc.id};
        return Position.fromJson(data);
      }).toList();
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Fetches only open positions for a user.
  Future<List<Position>> fetchOpenPositions(String uid) async {
    try {
      final snapshot = await _positionsCollection(uid)
          .where('isOpen', isEqualTo: true)
          .orderBy('expiration')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Position.fromJson(data);
      }).toList();
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Fetches a single position by ID.
  Future<Position?> fetchPosition(String uid, String positionId) async {
    try {
      final doc = await _positionsCollection(uid).doc(positionId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return Position.fromJson(data);
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Saves a new position. Returns the generated document ID.
  Future<String> createPosition({
    required String uid,
    required Position position,
  }) async {
    try {
      final docRef = await _positionsCollection(uid).add({
        ...position.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Updates an existing position.
  Future<void> updatePosition({
    required String uid,
    required String positionId,
    required Position position,
  }) async {
    try {
      await _positionsCollection(uid).doc(positionId).update({
        ...position.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Closes a position (sets isOpen to false).
  Future<void> closePosition({
    required String uid,
    required String positionId,
  }) async {
    try {
      await _positionsCollection(uid).doc(positionId).update({
        'isOpen': false,
        'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Deletes a position.
  Future<void> deletePosition({
    required String uid,
    required String positionId,
  }) async {
    try {
      await _positionsCollection(uid).doc(positionId).delete();
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Streams all positions for a user.
  Stream<List<Position>> streamPositions(String uid) {
    return _positionsCollection(uid)
        .orderBy('expiration')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Position.fromJson(data);
            }).toList());
  }

  /// Streams only open positions for a user.
  Stream<List<Position>> streamOpenPositions(String uid) {
    return _positionsCollection(uid)
        .where('isOpen', isEqualTo: true)
        .orderBy('expiration')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Position.fromJson(data);
            }).toList());
  }
}
