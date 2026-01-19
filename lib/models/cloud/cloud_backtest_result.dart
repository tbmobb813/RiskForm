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
    return CloudBacktestResult(
      jobId: m['jobId'] as String,
      userId: m['userId'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
      backtestResult: BacktestResult.fromMap(
        Map<String, dynamic>.from(m['backtestResult'] as Map),
      ),
    );
  }
}