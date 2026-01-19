import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../backtest/backtest_result.dart';

class CloudBacktestResult {
  final String jobId;
  final String userId;
  final DateTime createdAt;
  final BacktestResult backtestResult;

  CloudBacktestResult({
    required this.jobId,
    required this.userId,
    required this.createdAt,
    required this.backtestResult,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'backtestResult': backtestResult.toMap(),
    };
  }

  factory CloudBacktestResult.fromMap(Map<String, dynamic> m) {
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
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return CloudBacktestResult(
      jobId: m['jobId'] as String,
      userId: m['userId'] as String,
      createdAt: parseDate(m['createdAt'])!,
      backtestResult: BacktestResult.fromMap(
        Map<String, dynamic>.from(m['backtestResult'] as Map),
      ),
    );
  }
}