import 'package:cloud_functions/cloud_functions.dart';
import 'discipline_engine.dart';
import '../utils/payload_builders.dart' as pb;

/// Attempts to call the server-side `scoreTrade` callable function.
/// Falls back to the local `DisciplineEngine` if the callable fails.
class ServerScoring {
  /// Calls the server function; returns the total score on success.
  static Future<int> scoreTradeWithServer({
    required String journalId,
    required Map<String, dynamic> plannedParams,
    required Map<String, dynamic> executedParams,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('scoreTrade');

      // Build canonical payload using helper
      final payload = pb.buildScoreTradePayload(journalId: journalId, plannedParams: plannedParams, executedParams: executedParams);

      final res = await callable.call(payload);

      if (res.data != null && res.data['total'] != null) {
        return (res.data['total'] as num).toInt();
      }
    } catch (_) {
      // ignore and fall back to local scoring
    }

    // Fallback to local scoring
    final score = DisciplineEngine.scoreTrade(plannedParams: plannedParams, executedParams: executedParams);
    return score.total;
  }
}
