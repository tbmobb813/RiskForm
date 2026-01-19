import 'package:cloud_firestore/cloud_firestore.dart';

/// Recursively converts `DateTime` and Firestore `Timestamp` values to
/// ISO8601 strings so they can be safely passed to `httpsCallable`.
///
/// Usage:
/// final serialized = serializeForCallable(someMap);

dynamic serializeForCallable(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toUtc().toIso8601String();
  if (v is Timestamp) return v.toDate().toUtc().toIso8601String();
  if (v is Map) return _serializeMap(Map.from(v));
  if (v is List) return v.map(serializeForCallable).toList();
  return v;
}

Map<String, dynamic> _serializeMap(Map m) {
  final out = <String, dynamic>{};
  for (final entry in m.entries) {
    out[entry.key as String] = serializeForCallable(entry.value);
  }
  return out;
}
