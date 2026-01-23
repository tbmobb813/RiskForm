import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/position.dart';
import '../../../../services/firebase/position_service.dart';

/// Abstraction for fetching cockpit-related data. Tests can provide a fake
/// implementation to avoid depending on Firestore.
abstract class CockpitDataClient {
  Future<List<String>> fetchWatchlist(String uid);
  Future<List<Map<String, dynamic>>> fetchPendingJournals(String uid);
  Future<List<Map<String, dynamic>>> fetchRecentJournals(String uid);
  Future<List<Position>> fetchOpenPositions(String uid);
}

class DefaultCockpitDataClient implements CockpitDataClient {
  final FirebaseFirestore _firestore;
  final PositionService _posService;

  DefaultCockpitDataClient(this._posService, [FirebaseFirestore? firestore]) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<String>> fetchWatchlist(String uid) async {
    final wlDoc = await _firestore.collection('users').doc(uid).collection('cockpit').doc('watchlist').get();
    if (!wlDoc.exists) return [];
    final data = wlDoc.data();
    return (data?['tickers'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPendingJournals(String uid) async {
    final pjDoc = await _firestore.collection('users').doc(uid).collection('cockpit').doc('pendingJournals').get();
    if (!pjDoc.exists) return [];
    final data = pjDoc.data();
    return (data?['journals'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecentJournals(String uid) async {
    final q = await _firestore.collection('journalEntries').where('uid', isEqualTo: uid).orderBy('createdAt', descending: true).limit(20).get();
    return q.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
  }

  @override
  Future<List<Position>> fetchOpenPositions(String uid) async {
    return _posService.fetchOpenPositions(uid);
  }
}
