import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SmallAccountSettings {
  final bool enabled;
  final double startingCapital;
  final double maxAllocationPct; // 0.0 - 1.0
  final double minTradeSize;
  final int maxOpenPositions;

  const SmallAccountSettings({
    required this.enabled,
    required this.startingCapital,
    required this.maxAllocationPct,
    required this.minTradeSize,
    required this.maxOpenPositions,
  });

  SmallAccountSettings copyWith({
    bool? enabled,
    double? startingCapital,
    double? maxAllocationPct,
    double? minTradeSize,
    int? maxOpenPositions,
  }) {
    return SmallAccountSettings(
      enabled: enabled ?? this.enabled,
      startingCapital: startingCapital ?? this.startingCapital,
      maxAllocationPct: maxAllocationPct ?? this.maxAllocationPct,
      minTradeSize: minTradeSize ?? this.minTradeSize,
      maxOpenPositions: maxOpenPositions ?? this.maxOpenPositions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'startingCapital': startingCapital,
      'maxAllocationPct': maxAllocationPct,
      'minTradeSize': minTradeSize,
      'maxOpenPositions': maxOpenPositions,
    };
  }

  static SmallAccountSettings fromMap(Map<String, dynamic> m) {
    return SmallAccountSettings(
      enabled: m['enabled'] as bool? ?? false,
      startingCapital: (m['startingCapital'] as num?)?.toDouble() ?? 1000.0,
      maxAllocationPct: (m['maxAllocationPct'] as num?)?.toDouble() ?? 0.1,
      minTradeSize: (m['minTradeSize'] as num?)?.toDouble() ?? 10.0,
      maxOpenPositions: (m['maxOpenPositions'] as num?)?.toInt() ?? 3,
    );
  }
}

class SmallAccountState {
  final SmallAccountSettings settings;
  final Map<String, String> errors;
  final bool saving;

  SmallAccountState({
    required this.settings,
    this.errors = const {},
    this.saving = false,
  });

  SmallAccountState copyWith({SmallAccountSettings? settings, Map<String, String>? errors, bool? saving}) {
    return SmallAccountState(
      settings: settings ?? this.settings,
      errors: errors ?? this.errors,
      saving: saving ?? this.saving,
    );
  }
}

class SmallAccountNotifier extends StateNotifier<SmallAccountState> {
  static const _boxName = 'small_account_settings';
  static const _key = 'settings';

  SmallAccountNotifier()
      : super(SmallAccountState(
          settings: const SmallAccountSettings(
            enabled: false,
            startingCapital: 1000.0,
            maxAllocationPct: 0.1,
            minTradeSize: 10.0,
            maxOpenPositions: 3,
          ),
        )) {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    try {
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(_SmallAccountSettingsAdapter());
      final box = await Hive.openBox(_boxName);
      final stored = box.get(_key);
      if (stored is SmallAccountSettings) {
        state = state.copyWith(settings: stored);
      }
    } catch (_) {}
  }

  void updateEnabled(bool v) => state = state.copyWith(settings: state.settings.copyWith(enabled: v));

  void updateStartingCapital(double v) => state = state.copyWith(settings: state.settings.copyWith(startingCapital: v));

  void updateMaxAllocationPct(double v) => state = state.copyWith(settings: state.settings.copyWith(maxAllocationPct: v));

  void updateMinTradeSize(double v) => state = state.copyWith(settings: state.settings.copyWith(minTradeSize: v));

  void updateMaxOpenPositions(int v) => state = state.copyWith(settings: state.settings.copyWith(maxOpenPositions: v));

  Map<String, String> validate(SmallAccountSettings s) {
    final errs = <String, String>{};
    if (s.startingCapital <= 0) errs['startingCapital'] = 'Starting capital must be > 0';
    if (s.maxAllocationPct <= 0 || s.maxAllocationPct > 1) errs['maxAllocationPct'] = 'Must be between 0 and 1';
    if (s.minTradeSize <= 0) errs['minTradeSize'] = 'Min trade size must be > 0';
    if (s.minTradeSize > s.startingCapital) errs['minTradeSize'] = 'Min trade size cannot exceed starting capital';
    if (s.maxOpenPositions <= 0) errs['maxOpenPositions'] = 'Must allow at least 1 open position';
    return errs;
  }

  Future<bool> save() async {
    final errs = validate(state.settings);
    state = state.copyWith(errors: errs);
    if (errs.isNotEmpty) return false;
    state = state.copyWith(saving: true);
    try {
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(_SmallAccountSettingsAdapter());
      final box = await Hive.openBox(_boxName);
      await box.put(_key, state.settings);
      // Also persist to Firestore if user is signed in so server-side functions can enforce rules
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = FirebaseFirestore.instance.doc('users/$uid/smallAccountSettings');
          await doc.set(state.settings.toMap());
        }
      } catch (_) {
        // Firebase not initialized in test environment — ignore
      }
    } catch (_) {
      state = state.copyWith(saving: false);
      return false;
    }
    state = state.copyWith(saving: false);
    return true;
  }
}

final smallAccountProvider = StateNotifierProvider<SmallAccountNotifier, SmallAccountState>((ref) => SmallAccountNotifier());

class _SmallAccountSettingsAdapter extends TypeAdapter<SmallAccountSettings> {
  @override
  final int typeId = 1;

  @override
  SmallAccountSettings read(BinaryReader reader) {
    final enabled = reader.readBool();
    final startingCapital = reader.readDouble();
    final maxAllocationPct = reader.readDouble();
    final minTradeSize = reader.readDouble();
    final maxOpenPositions = reader.readInt();
    return SmallAccountSettings(
      enabled: enabled,
      startingCapital: startingCapital,
      maxAllocationPct: maxAllocationPct,
      minTradeSize: minTradeSize,
      maxOpenPositions: maxOpenPositions,
    );
  }

  @override
  void write(BinaryWriter writer, SmallAccountSettings obj) {
    writer.writeBool(obj.enabled);
    writer.writeDouble(obj.startingCapital);
    writer.writeDouble(obj.maxAllocationPct);
    writer.writeDouble(obj.minTradeSize);
    writer.writeInt(obj.maxOpenPositions);
  }
}
