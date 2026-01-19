import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is Timestamp) return v.toDate();
  if (v is Map && v.containsKey('_seconds')) {
    final s = v['_seconds'] as int? ?? 0;
    final ns = v['_nanoseconds'] as int? ?? 0;
    final ms = s * 1000 + (ns ~/ 1000000);
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}
