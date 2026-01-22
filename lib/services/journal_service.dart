import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class JournalService {
  final FirebaseFirestore? _firestore;

  JournalService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference _userJournals(String userId) =>
      _db.collection('users').doc(userId).collection('journals');

  Future<String> createEntryForStrategy({
    required String userId,
    required String strategyId,
    required String strategyName,
    String? description,
    String? strategySymbol,
    String? notes,
    List<String>? tags,
  }) async {
    final docRef = _userJournals(userId).doc();
    final entry = JournalEntry(
      id: docRef.id,
      userId: userId,
      strategyId: strategyId,
      strategyName: strategyName,
      strategySymbol: strategySymbol,
      description: description,
      notes: notes ?? '',
      tags: tags ?? [],
    );

    await docRef.set(entry.toFirestore());
    return docRef.id;
  }

  Future<void> updateEntry(String userId, String entryId, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await _userJournals(userId).doc(entryId).update(fields);
  }

  Future<List<JournalEntry>> listForUser(String userId, {int limit = 50}) async {
    final snap = await _userJournals(userId).orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map((d) => JournalEntry.fromFirestore(d)).toList();
  }
}
