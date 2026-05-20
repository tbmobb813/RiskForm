import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/imported_trade.dart';

class TradeImportService {
  final FirebaseFirestore _db;

  TradeImportService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference _col(String userId) =>
      _db.collection('users').doc(userId).collection('importedTrades');

  /// Saves [trades] in a single batched write. Returns the count saved.
  Future<int> saveBatch(String userId, List<ImportedTrade> trades) async {
    if (trades.isEmpty) return 0;

    // Firestore batch limit is 500 writes — chunk if needed
    int saved = 0;
    for (int i = 0; i < trades.length; i += 400) {
      final chunk = trades.sublist(i, (i + 400).clamp(0, trades.length));
      final batch = _db.batch();
      for (final t in chunk) {
        final ref = _col(userId).doc(t.id);
        batch.set(ref, t.toFirestore());
      }
      await batch.commit();
      saved += chunk.length;
    }
    return saved;
  }

  /// Fetches recent imported trades, newest first.
  Future<List<Map<String, dynamic>>> fetchRecent(
    String userId, {
    int limit = 100,
  }) async {
    final snap = await _col(
      userId,
    ).orderBy('importedAt', descending: true).limit(limit).get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }
}
