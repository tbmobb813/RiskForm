import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exceptions/app_exceptions.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

/// Base Firestore service providing common CRUD operations.
/// Subclasses can extend this for collection-specific functionality.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  /// Gets a reference to a collection.
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }

  /// Gets a reference to a document.
  DocumentReference<Map<String, dynamic>> doc(String collectionPath, String docId) {
    return _db.collection(collectionPath).doc(docId);
  }

  /// Creates a new document with auto-generated ID.
  Future<String> create({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _db.collection(collectionPath).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Creates or overwrites a document with a specific ID.
  Future<void> set({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await _db.collection(collectionPath).doc(docId).set(
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!merge) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: merge),
      );
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Updates specific fields in a document.
  Future<void> update({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collectionPath).doc(docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Deletes a document.
  Future<void> delete({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      await _db.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Gets a single document by ID.
  /// Returns null if document doesn't exist.
  Future<Map<String, dynamic>?> get({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      final snapshot = await _db.collection(collectionPath).doc(docId).get();
      if (!snapshot.exists) return null;
      return {'id': snapshot.id, ...?snapshot.data()};
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Gets a single document or throws if not found.
  Future<Map<String, dynamic>> getOrThrow({
    required String collectionPath,
    required String docId,
  }) async {
    final data = await get(collectionPath: collectionPath, docId: docId);
    if (data == null) {
      throw FirestoreException.notFound(collectionPath, docId);
    }
    return data;
  }

  /// Queries documents in a collection.
  Future<List<Map<String, dynamic>>> query({
    required String collectionPath,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(collectionPath);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = filter.apply(query);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Streams a single document.
  Stream<Map<String, dynamic>?> streamDoc({
    required String collectionPath,
    required String docId,
  }) {
    return _db.collection(collectionPath).doc(docId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return {'id': snapshot.id, ...?snapshot.data()};
    });
  }

  /// Streams a collection query.
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collectionPath,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);

    if (filters != null) {
      for (final filter in filters) {
        query = filter.apply(query);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        );
  }

  /// Runs a batch write operation.
  Future<void> batch(void Function(WriteBatch batch) operations) async {
    try {
      final batch = _db.batch();
      operations(batch);
      await batch.commit();
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }

  /// Runs a transaction.
  Future<T> transaction<T>(Future<T> Function(Transaction transaction) operations) async {
    try {
      return await _db.runTransaction(operations);
    } catch (e) {
      throw FirestoreException.fromError(e);
    }
  }
}

/// Filter for Firestore queries.
class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  const QueryFilter(this.field, this.operator, this.value);

  factory QueryFilter.equals(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.equals, value);

  factory QueryFilter.notEquals(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.notEquals, value);

  factory QueryFilter.lessThan(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.lessThan, value);

  factory QueryFilter.lessThanOrEquals(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.lessThanOrEquals, value);

  factory QueryFilter.greaterThan(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.greaterThan, value);

  factory QueryFilter.greaterThanOrEquals(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.greaterThanOrEquals, value);

  factory QueryFilter.arrayContains(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.arrayContains, value);

  Query<Map<String, dynamic>> apply(Query<Map<String, dynamic>> query) {
    switch (operator) {
      case FilterOperator.equals:
        return query.where(field, isEqualTo: value);
      case FilterOperator.notEquals:
        return query.where(field, isNotEqualTo: value);
      case FilterOperator.lessThan:
        return query.where(field, isLessThan: value);
      case FilterOperator.lessThanOrEquals:
        return query.where(field, isLessThanOrEqualTo: value);
      case FilterOperator.greaterThan:
        return query.where(field, isGreaterThan: value);
      case FilterOperator.greaterThanOrEquals:
        return query.where(field, isGreaterThanOrEqualTo: value);
      case FilterOperator.arrayContains:
        return query.where(field, arrayContains: value);
    }
  }
}

enum FilterOperator {
  equals,
  notEquals,
  lessThan,
  lessThanOrEquals,
  greaterThan,
  greaterThanOrEquals,
  arrayContains,
}
