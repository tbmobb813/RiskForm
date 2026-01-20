import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exceptions/app_exceptions.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Service for user profile and settings operations in Firestore.
class UserService {
  final FirebaseFirestore _db;

  UserService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  /// Fetches user profile data.
  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Creates or updates user profile.
  Future<void> saveProfile({
    required String uid,
    required Map<String, dynamic> profile,
  }) async {
    try {
      await _userDoc(uid).set({
        ...profile,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Creates a new user document on first sign-up.
  Future<void> createUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      await _userDoc(uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Default settings
        'settings': {
          'notifications': true,
          'theme': 'system',
        },
        // Default risk profile
        'riskProfile': {
          'id': 'default',
          'maxRiskPercent': 2.0,
        },
        // Default account (placeholder until connected)
        'account': {
          'accountSize': 0,
          'buyingPower': 0,
        },
      });
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Updates user settings.
  Future<void> updateSettings({
    required String uid,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _userDoc(uid).update({
        'settings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Checks if a user document exists.
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      return doc.exists;
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Streams user profile changes.
  Stream<Map<String, dynamic>?> streamProfile(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }
}
