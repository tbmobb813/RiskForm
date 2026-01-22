import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore helpers: convert client-side values into Firestore-friendly
/// representations and perform shallow sanitization.

Timestamp? toTimestamp(DateTime? dt) => dt == null ? null : Timestamp.fromDate(dt);

Map<String, dynamic> normalizeDateFields(Map<String, dynamic> m, Iterable<String> keys) {
  final out = Map<String, dynamic>.from(m);
  for (final k in keys) {
    final v = out[k];
    if (v is DateTime) {
      out[k] = Timestamp.fromDate(v);
    }
  }
  return out;
}

dynamic toFirestoreValue(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return Timestamp.fromDate(v);
  if (v is Timestamp) return v;
  if (v is Map) return toFirestoreMap(Map.from(v));
  if (v is List) return v.map(toFirestoreValue).toList();
  return v;
}

Map<String, dynamic> toFirestoreMap(Map m) {
  final out = <String, dynamic>{};
  for (final e in m.entries) {
    out[e.key as String] = toFirestoreValue(e.value);
  }
  return out;
}

Map<String, dynamic> stripNulls(Map m) {
  final out = <String, dynamic>{};
  for (final e in m.entries) {
    if (e.value != null) out[e.key as String] = e.value;
  }
  return out;
}
