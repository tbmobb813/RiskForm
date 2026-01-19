import 'serialize_for_callable.dart' as _ser;

/// Small payload builders for cloud callables.

Map<String, dynamic> buildScoreTradePayload({
  required String journalId,
  required Map<String, dynamic> plannedParams,
  required Map<String, dynamic> executedParams,
}) {
  return {
    'journalId': journalId,
    'plannedParams': _ser.serializeForCallable(plannedParams),
    'executedParams': _ser.serializeForCallable(executedParams),
  };
}
