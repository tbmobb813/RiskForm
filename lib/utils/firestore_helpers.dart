import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore helpers: convert client-side values into Firestore-friendly
/// representations and perform shallow sanitization.

/// Convert a single value to a Firestore-friendly value:
/// - `DateTime` -> `Timestamp`
/// - `Map` -> recursively convert keys
/// - `List` -> map values
/// - others -> returned as-is
dynamic toFirestoreValue(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return Timestamp.fromDate(v);
  if (v is Timestamp) return v;
  if (v is Map) return toFirestoreMap(Map.from(v));
  if (v is List) return v.map(toFirestoreValue).toList();
  return v;
}

/// Convert a Map's values to Firestore-friendly values (shallow keys preserved).
Map<String, dynamic> toFirestoreMap(Map m) {
  final out = <String, dynamic>{};
  for (final e in m.entries) {
    out[e.key as String] = toFirestoreValue(e.value);
  }
  return out;
}

/// Remove null values from a Map (shallow). Useful before writes when
/// you want to avoid storing explicit nulls.
Map<String, dynamic> stripNulls(Map m) {
  final out = <String, dynamic>{};
  for (final e in m.entries) {
    if (e.value != null) out[e.key as String] = e.value;
  }
  return out;
}
