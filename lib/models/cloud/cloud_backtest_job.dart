import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../backtest/backtest_config.dart';

enum CloudBacktestStatus { queued, running, completed, failed }

class CloudBacktestJob {
  final String jobId;
  final String userId;
  final DateTime submittedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final CloudBacktestStatus status;
  final BacktestConfig configUsed;
  final String engineVersion;
  final int? priority;
  final String? errorMessage;

  CloudBacktestJob({
    required this.jobId,
    required this.userId,
    required this.submittedAt,
    this.startedAt,
    this.completedAt,
    required this.status,
    required this.configUsed,
    required this.engineVersion,
    this.priority,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'userId': userId,
      'submittedAt': submittedAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.toString(),
      'configUsed': configUsed.toMap(),
      'engineVersion': engineVersion,
      'priority': priority,
      'errorMessage': errorMessage,
    };
  }

  factory CloudBacktestJob.fromMap(Map<String, dynamic> m) {
    String statusRaw = m['status'] as String;
    final statusToken = statusRaw.contains('.') ? statusRaw.split('.').last : statusRaw;
    final status = CloudBacktestStatus.values
        .firstWhere((e) => e.toString().split('.').last == statusToken);

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          // fall through to other attempts and eventually return null
        }
      }
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is Timestamp) return v.toDate();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return CloudBacktestJob(
      jobId: m['jobId'] as String,
      userId: m['userId'] as String,
      submittedAt: parseDate(m['submittedAt'])!,
      startedAt: parseDate(m['startedAt']),
      completedAt: parseDate(m['completedAt']),
      status: status,
      configUsed: BacktestConfig.fromMap(Map<String, dynamic>.from(m['configUsed'] as Map)),
      engineVersion: m['engineVersion'] as String,
      priority: (m['priority'] as num?)?.toInt(),
      errorMessage: m['errorMessage'] as String?,
    );
  }
}