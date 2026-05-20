import 'package:cloud_functions/cloud_functions.dart';
import '../models/signal_model.dart';

class SignalService {
  final FirebaseFunctions _functions;

  SignalService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  /// Calls the [generateSignal] Cloud Function for [ticker].
  /// Returns the parsed [SignalModel] on success.
  Future<SignalModel> generateSignal(String ticker) async {
    final callable = _functions.httpsCallable(
      'generateSignal',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    final result = await callable.call<Map<String, dynamic>>({
      'ticker': ticker,
    });
    final data = result.data;

    final signalJson = data['signal'] as Map<String, dynamic>? ?? {};
    final queries =
        (data['searchQueries'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        [];

    return SignalModel.fromJson(signalJson, searchQueries: queries);
  }
}
