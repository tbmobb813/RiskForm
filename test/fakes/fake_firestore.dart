// test fakes extend sealed Firestore types; ignore related analyzer warnings here
// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides, unnecessary_brace_in_string_interps, invalid_null_aware_operator, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';

class InMemoryDoc {
  Map<String, dynamic> data;
  InMemoryDoc(this.data);
}

class FakeDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic> data() => Map<String, dynamic>.from(_data ?? {});

  @override
  dynamic get(Object field) => _data?[field as String];

  @override
  bool get exists => _data != null;

  @override
  // unused members
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  final String path;
  final Map<String, InMemoryDoc> store;

  FakeDocumentReference(this.path, this.store);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    store[path] = InMemoryDoc(Map<String, dynamic>.from(data));
  }

  @override
  Future<FakeDocumentSnapshot> get([GetOptions? options]) async {
    final doc = store[path];
    return FakeDocumentSnapshot(path.split('/').last, doc?.data);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String pathSegment) {
    final collPath = '$path/$pathSegment';
    return FakeCollectionReference(collPath, store);
  }

  // minimal implementations
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>>, Query<Map<String, dynamic>> {
  @override
  final String path;
  final Map<String, InMemoryDoc> store;
  String? _orderField;
  bool _orderDesc = false;

  FakeCollectionReference(this.path, this.store);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) {
    final docId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final childPath = '${path}/${docId}';
    return FakeDocumentReference(childPath, store);
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    // record ordering parameters and apply in get()
    _orderField = field?.toString();
    _orderDesc = descending;
    return this as Query<Map<String, dynamic>>;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    // return all docs under this collection path
    final docs = <FakeDocumentSnapshot>[];
    store.forEach((k, v) {
      if (k.startsWith('$path/')) {
        final id = k.split('/').last;
        docs.add(FakeDocumentSnapshot(id, v.data));
      }
    });

    if (_orderField != null && _orderField == 'createdAt') {
      docs.sort((a, b) {
        final ma = a.data()['createdAt'];
        final mb = b.data()['createdAt'];
        int va = 0;
        int vb = 0;
        try {
          if (ma is Timestamp) va = ma.toDate().millisecondsSinceEpoch;
          else if (ma is String) va = DateTime.parse(ma).millisecondsSinceEpoch;
        } catch (_) {}
        try {
          if (mb is Timestamp) vb = mb.toDate().millisecondsSinceEpoch;
          else if (mb is String) vb = DateTime.parse(mb).millisecondsSinceEpoch;
        } catch (_) {}
        return _orderDesc ? vb.compareTo(va) : va.compareTo(vb);
      });
    }

    return _FakeQuerySnapshot(docs);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  final List<FakeDocumentSnapshot> _docs;
  _FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, InMemoryDoc> store = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReference(path, store);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
