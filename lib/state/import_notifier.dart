import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/imported_trade.dart';
import '../services/import/csv_parsers.dart';
import '../services/import/trade_import_service.dart';

enum ImportStep { idle, picked, reviewing, saving, done, error }

class ImportState {
  final ImportStep step;
  final ImportBroker broker;
  final List<ImportedTrade> trades;
  final String? fileName;
  final String? errorMessage;
  final int savedCount;

  const ImportState({
    this.step = ImportStep.idle,
    this.broker = ImportBroker.tastytrade,
    this.trades = const [],
    this.fileName,
    this.errorMessage,
    this.savedCount = 0,
  });

  int get selectedCount => trades.where((t) => t.selected).length;

  ImportState copyWith({
    ImportStep? step,
    ImportBroker? broker,
    List<ImportedTrade>? trades,
    String? fileName,
    String? errorMessage,
    int? savedCount,
  }) => ImportState(
    step: step ?? this.step,
    broker: broker ?? this.broker,
    trades: trades ?? this.trades,
    fileName: fileName ?? this.fileName,
    errorMessage: errorMessage ?? this.errorMessage,
    savedCount: savedCount ?? this.savedCount,
  );
}

class ImportNotifier extends Notifier<ImportState> {
  late final TradeImportService _service;

  @override
  ImportState build() {
    _service = TradeImportService();
    return const ImportState();
  }

  void setBroker(ImportBroker broker) {
    state = state.copyWith(broker: broker, step: ImportStep.idle, trades: []);
  }

  Future<void> pickAndParse() async {
    state = state.copyWith(step: ImportStep.picked, errorMessage: null);

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
    } catch (e) {
      state = state.copyWith(
        step: ImportStep.error,
        errorMessage: 'Could not open file picker: $e',
      );
      return;
    }

    if (result == null || result.files.isEmpty) {
      state = state.copyWith(step: ImportStep.idle);
      return;
    }

    final file = result.files.first;
    String csvContent;

    try {
      if (file.bytes != null) {
        csvContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      } else {
        throw Exception('No file content available.');
      }
    } catch (e) {
      state = state.copyWith(
        step: ImportStep.error,
        errorMessage: 'Failed to read file: $e',
      );
      return;
    }

    List<ImportedTrade> trades;
    try {
      trades = switch (state.broker) {
        ImportBroker.tastytrade => parseTastytrade(csvContent),
        ImportBroker.thinkorswim => parseThinkorswim(csvContent),
        ImportBroker.robinhood => parseRobinhood(csvContent),
        ImportBroker.fidelity => parseFidelity(csvContent),
      };
    } catch (e) {
      state = state.copyWith(
        step: ImportStep.error,
        errorMessage: 'Parse error: $e',
      );
      return;
    }

    if (trades.isEmpty) {
      state = state.copyWith(
        step: ImportStep.error,
        errorMessage:
            'No trades found. Make sure the file is a valid '
            '${state.broker.displayName} export.',
      );
      return;
    }

    state = state.copyWith(
      step: ImportStep.reviewing,
      trades: trades,
      fileName: file.name,
    );
  }

  void toggleTrade(int index) {
    final updated = List<ImportedTrade>.from(state.trades);
    updated[index].selected = !updated[index].selected;
    state = state.copyWith(trades: updated);
  }

  void selectAll(bool value) {
    final updated = state.trades.map((t) {
      t.selected = value;
      return t;
    }).toList();
    state = state.copyWith(trades: updated);
  }

  Future<void> confirmImport(String userId) async {
    final toSave = state.trades.where((t) => t.selected).toList();
    if (toSave.isEmpty) return;

    state = state.copyWith(step: ImportStep.saving);
    try {
      final count = await _service.saveBatch(userId, toSave);
      state = state.copyWith(step: ImportStep.done, savedCount: count);
    } catch (e) {
      state = state.copyWith(
        step: ImportStep.error,
        errorMessage: 'Save failed: $e',
      );
    }
  }

  void reset() => state = ImportState(broker: state.broker);
}

extension on ImportBroker {
  String get displayName => switch (this) {
    ImportBroker.tastytrade => 'tastytrade',
    ImportBroker.thinkorswim => 'thinkorSwim',
    ImportBroker.robinhood => 'Robinhood',
    ImportBroker.fidelity => 'Fidelity',
  };
}

final importProvider = NotifierProvider<ImportNotifier, ImportState>(
  ImportNotifier.new,
);
