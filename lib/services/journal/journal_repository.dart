import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/journal/journal_entry.dart';

class JournalRepository extends ChangeNotifier {
  final List<JournalEntry> _entries = [];
  final FirebaseFirestore? _firestore;
  final String? _userId;

  JournalRepository({FirebaseFirestore? firestore, String? userId})
      : _firestore = firestore,
        _userId = userId {
    if (_firestore != null && _userId != null) {
      _loadFromFirestore();
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference _userJournals(String uid) =>
      _db.collection('users').doc(uid).collection('journals');

  Future<void> _loadFromFirestore() async {
    try {
      final snap = await _userJournals(_userId!).orderBy('timestamp', descending: true).get();
      _entries.clear();
      for (final d in snap.docs) {
        _entries.add(JournalEntry.fromFirestore(d));
      }
      notifyListeners();
    } catch (_) {
      // ignore errors and keep in-memory entries
    }
  }

  Future<void> addEntry(JournalEntry entry) async {
    _entries.insert(0, entry);
    notifyListeners();
    if (_firestore != null && _userId != null) {
      try {
        final docRef = _userJournals(_userId).doc(entry.id);
        await docRef.set(entry.toFirestore());
      } catch (_) {}
    }
  }

  /// Replace an existing entry with the same id. If not found, add it.
  Future<void> updateEntry(JournalEntry entry) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _entries[idx] = entry;
    } else {
      _entries.insert(0, entry);
    }
    notifyListeners();
    if (_firestore != null && _userId != null) {
      try {
        final docRef = _userJournals(_userId).doc(entry.id);
        await docRef.set(entry.toFirestore(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<JournalEntry?> getById(String id) async {
    try {
      final local = _entries.firstWhere((e) => e.id == id);
      return local;
    } catch (_) {
      if (_firestore != null && _userId != null) {
        try {
          final doc = await _userJournals(_userId).doc(id).get();
          if (doc.exists) {
            final entry = JournalEntry.fromFirestore(doc);
            _entries.insert(0, entry);
            notifyListeners();
            return entry;
          }
        } catch (_) {}
      }
      return null;
    }
  }

  List<JournalEntry> getAll() => List.unmodifiable(_entries);

  /// Delete an entry locally and from Firestore when available.
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    if (_firestore != null && _userId != null) {
      try {
        await _userJournals(_userId).doc(id).delete();
      } catch (_) {}
    }
  }
}
