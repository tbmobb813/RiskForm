import 'package:cloud_firestore/cloud_firestore.dart';

enum StrategyState {
  active,
  paused,
  retired,
  experimental,
}

class Strategy {
  final String id;
  final String name;
  final String? description;
  final StrategyState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? retiredAt;
  final List<String> tags;
  final Map<String, dynamic> constraints;

  const Strategy({
    required this.id,
    required this.name,
    this.description,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.retiredAt,
    this.tags = const [],
    this.constraints = const {},
  });

  // -----------------------------
  // Factory: Firestore → Strategy
  // -----------------------------
  factory Strategy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Strategy(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      state: _parseState(data['state'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      retiredAt: data['retiredAt'] != null
          ? (data['retiredAt'] as Timestamp).toDate()
          : null,
      tags: List<String>.from(data['tags'] ?? []),
      constraints: Map<String, dynamic>.from(data['constraints'] ?? {}),
    );
  }

    /// Factory: Map (id + data) -> Strategy
    factory Strategy.fromMap(String id, Map<String, dynamic> data) {
      DateTime parseTs(Object? v) {
        if (v == null) return DateTime.now();
        if (v is DateTime) return v;
        if (v is Timestamp) return v.toDate();
        return DateTime.now();
      }

      return Strategy(
        id: id,
        name: data['name'] as String,
        description: data['description'] as String?,
        state: _parseState(data['state'] as String),
        createdAt: parseTs(data['createdAt']),
        updatedAt: parseTs(data['updatedAt']),
        retiredAt: data['retiredAt'] != null ? parseTs(data['retiredAt']) : null,
        tags: List<String>.from(data['tags'] ?? []),
        constraints: Map<String, dynamic>.from(data['constraints'] ?? {}),
      );
    }

  // -----------------------------
  // Convert to Firestore
  // -----------------------------
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'state': state.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (retiredAt != null) 'retiredAt': Timestamp.fromDate(retiredAt!),
      'tags': tags,
      'constraints': constraints,
    };
  }

  // -----------------------------
  // Copy With (Immutable Updates)
  // -----------------------------
  Strategy copyWith({
    String? name,
    String? description,
    StrategyState? state,
    DateTime? updatedAt,
    DateTime? retiredAt,
    List<String>? tags,
    Map<String, dynamic>? constraints,
  }) {
    return Strategy(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retiredAt: retiredAt ?? this.retiredAt,
      tags: tags ?? this.tags,
      constraints: constraints ?? this.constraints,
    );
  }

  // -----------------------------
  // Helpers
  // -----------------------------
  static StrategyState _parseState(String raw) {
    switch (raw) {
      case 'active':
        return StrategyState.active;
      case 'paused':
        return StrategyState.paused;
      case 'retired':
        return StrategyState.retired;
      case 'experimental':
        return StrategyState.experimental;
      default:
        throw Exception('Invalid strategy state: $raw');
    }
  }
}
