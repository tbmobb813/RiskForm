import 'package:cloud_functions/cloud_functions.dart';
import 'discipline_engine.dart';

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

      // Convert DateTime to ISO strings if present
      final planCopy = Map<String, dynamic>.from(plannedParams);
      planCopy.updateAll((k, v) => v is DateTime ? v.toIso8601String() : v);

      final execCopy = Map<String, dynamic>.from(executedParams);
      execCopy.updateAll((k, v) => v is DateTime ? v.toIso8601String() : v);

      final res = await callable.call(<String, dynamic>{
        'journalId': journalId,
        'plannedParams': planCopy,
        'executedParams': execCopy,
      });

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
