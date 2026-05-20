import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/best_opp_model.dart';
import '../services/best_opp_service.dart';

class BestOppState {
  final List<BestOppModel> opps;
  final bool isLoading;
  final bool showAll;
  final String selectedDate; // yyyy-MM-dd
  final String? error;

  const BestOppState({
    this.opps = const [],
    this.isLoading = false,
    this.showAll = false,
    required this.selectedDate,
    this.error,
  });

  BestOppState copyWith({
    List<BestOppModel>? opps,
    bool? isLoading,
    bool? showAll,
    String? selectedDate,
    String? error,
    bool clearError = false,
  }) => BestOppState(
    opps: opps ?? this.opps,
    isLoading: isLoading ?? this.isLoading,
    showAll: showAll ?? this.showAll,
    selectedDate: selectedDate ?? this.selectedDate,
    error: clearError ? null : (error ?? this.error),
  );
}

class BestOppNotifier extends Notifier<BestOppState> {
  late final BestOppService _service;

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  BestOppState build() {
    _service = BestOppService();
    return BestOppState(selectedDate: _today());
  }

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final opps = state.showAll
          ? await _service.listAll(userId)
          : await _service.listByDate(userId, state.selectedDate);
      state = state.copyWith(opps: opps, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setDate(String userId, String date) {
    state = state.copyWith(selectedDate: date, showAll: false);
    load(userId);
  }

  void stepDate(String userId, int days) {
    final current = DateTime.parse(state.selectedDate);
    final next = current.add(Duration(days: days));
    final formatted =
        '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
    setDate(userId, formatted);
  }

  void toggleShowAll(String userId) {
    state = state.copyWith(showAll: !state.showAll);
    load(userId);
  }

  Future<void> addOpp({
    required String userId,
    required String ticker,
    required String setup,
    required String entryTrigger,
    required String whatMadeItIdeal,
    required bool wasTaken,
    String? screenshotUrl,
    String? notes,
  }) async {
    final opp = await _service.create(
      userId: userId,
      date: state.selectedDate,
      ticker: ticker,
      setup: setup,
      entryTrigger: entryTrigger,
      whatMadeItIdeal: whatMadeItIdeal,
      wasTaken: wasTaken,
      screenshotUrl: screenshotUrl,
      notes: notes,
    );
    // Only prepend if visible under current filter
    final visible = state.showAll || opp.date == state.selectedDate;
    if (visible) {
      state = state.copyWith(opps: [opp, ...state.opps]);
    }
  }

  Future<void> toggleTaken(String userId, BestOppModel opp) async {
    final updated = opp.copyWith(wasTaken: !opp.wasTaken);
    await _service.toggleTaken(userId, opp.id, updated.wasTaken);
    state = state.copyWith(
      opps: state.opps.map((o) => o.id == opp.id ? updated : o).toList(),
    );
  }

  Future<void> delete(String userId, String oppId) async {
    await _service.delete(userId, oppId);
    state = state.copyWith(
      opps: state.opps.where((o) => o.id != oppId).toList(),
    );
  }
}

final bestOppProvider = NotifierProvider<BestOppNotifier, BestOppState>(
  BestOppNotifier.new,
);
