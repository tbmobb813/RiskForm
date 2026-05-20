import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/signal_model.dart';
import '../services/signal_service.dart';

enum LogType { info, success, error }

class LogLine {
  final String time;
  final String text;
  final LogType type;

  const LogLine({required this.time, required this.text, required this.type});
}

class SignalEngineState {
  final List<SignalModel> signals;
  final bool isLoading;
  final List<LogLine> logs;
  final String? error;

  const SignalEngineState({
    this.signals = const [],
    this.isLoading = false,
    this.logs = const [],
    this.error,
  });

  SignalEngineState copyWith({
    List<SignalModel>? signals,
    bool? isLoading,
    List<LogLine>? logs,
    String? error,
    bool clearError = false,
  }) {
    return SignalEngineState(
      signals: signals ?? this.signals,
      isLoading: isLoading ?? this.isLoading,
      logs: logs ?? this.logs,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Riverpod 3.x: use Notifier<State> instead of StateNotifier<State>
class SignalEngineNotifier extends Notifier<SignalEngineState> {
  late final SignalService _service;

  @override
  SignalEngineState build() {
    _service = SignalService();
    return const SignalEngineState();
  }

  void _log(String text, {LogType type = LogType.info}) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final line = LogLine(time: time, text: text, type: type);
    final current = state.logs;
    final trimmed = current.length >= 80
        ? current.sublist(current.length - 79)
        : current;
    state = state.copyWith(logs: [...trimmed, line]);
  }

  Future<void> generateSignals(List<String> tickers) async {
    if (tickers.isEmpty) return;
    state = state.copyWith(isLoading: true, logs: [], clearError: true);

    _log(
      'Starting signal engine — ${tickers.length} ticker(s)',
      type: LogType.success,
    );

    final newSignals = <SignalModel>[];

    for (final ticker in tickers) {
      _log('Processing $ticker...');
      try {
        final sig = await _service.generateSignal(ticker);
        for (final q in sig.searchQueries) {
          _log('↳ web_search: "$q"');
        }
        newSignals.add(sig);
        _log(
          'Signal: $ticker → ${sig.signal.name} (${sig.confidence}% confidence)',
          type: LogType.success,
        );
      } catch (e) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        _log('ERROR on $ticker: $msg', type: LogType.error);
        state = state.copyWith(error: msg);
      }
    }

    state = state.copyWith(
      signals: [...newSignals, ...state.signals],
      isLoading: false,
    );
    _log(
      'Engine complete. ${newSignals.length}/${tickers.length} signals generated.',
      type: LogType.success,
    );
  }

  void removeSignal(int index) {
    final updated = [...state.signals]..removeAt(index);
    state = state.copyWith(signals: updated);
  }

  void clearSignals() => state = state.copyWith(signals: []);
}

final signalEngineProvider =
    NotifierProvider<SignalEngineNotifier, SignalEngineState>(
      SignalEngineNotifier.new,
    );
