import 'package:cloud_functions/cloud_functions.dart';
import 'discipline_engine.dart';
import '../utils/serialize_for_callable.dart' as _ser;

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

      // Serialize DateTime / Timestamp values recursively for transport
      final planCopy = _ser.serializeForCallable(plannedParams) as Map<String, dynamic>;
      final execCopy = _ser.serializeForCallable(executedParams) as Map<String, dynamic>;

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
