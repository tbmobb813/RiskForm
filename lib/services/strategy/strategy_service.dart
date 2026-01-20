import 'package:cloud_firestore/cloud_firestore.dart';

enum StrategyState {
  active,
  paused,
  retired,
  experimental,
}

class StrategyService {
  final FirebaseFirestore _firestore;

  StrategyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // -----------------------------
  // Collection references
  // -----------------------------
  CollectionReference get _strategies => _firestore.collection('strategies');

  CollectionReference get _events => _firestore.collection('strategyEvents');

  // -----------------------------
  // Create Strategy
  // -----------------------------
  Future<String> createStrategy({
    required String name,
    String? description,
    List<String> tags = const [],
    Map<String, dynamic>? constraints,
    bool experimental = false,
  }) async {
    final docRef = _strategies.doc();

    final state = experimental
        ? StrategyState.experimental.name
        : StrategyState.active.name;

    await docRef.set({
      'name': name,
      'description': description,
      'state': state,
      'tags': tags,
      'constraints': constraints ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _events.add({
      'strategyId': docRef.id,
      'type': 'created',
      'timestamp': FieldValue.serverTimestamp(),
      'previousState': null,
      'nextState': state,
    });

    return docRef.id;
  }

  // -----------------------------
  // Update Strategy Metadata
  // -----------------------------
  Future<void> updateStrategy({
    required String strategyId,
    String? name,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? constraints,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (tags != null) updateData['tags'] = tags;
    if (constraints != null) updateData['constraints'] = constraints;

    await _strategies.doc(strategyId).update(updateData);
  }

  // -----------------------------
  // Change Strategy State
  // -----------------------------
  Future<void> changeStrategyState({
    required String strategyId,
    required StrategyState nextState,
    String? reason,
  }) async {
    final doc = await _strategies.doc(strategyId).get();
    if (!doc.exists) {
      throw Exception('Strategy not found: $strategyId');
    }

    final data = doc.data() as Map<String, dynamic>;
    final previousState = (data['state'] as String?) ?? 'created';

    _validateTransition(previousState, nextState.name);

    final updateData = {
      'state': nextState.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (nextState == StrategyState.retired) {
      updateData['retiredAt'] = FieldValue.serverTimestamp();
    }

    await _strategies.doc(strategyId).update(updateData);

    await _events.add({
      'strategyId': strategyId,
      'type': _eventType(previousState, nextState.name),
      'timestamp': FieldValue.serverTimestamp(),
      'reason': reason,
      'previousState': previousState,
      'nextState': nextState.name,
    });
  }

  // -----------------------------
  // Fetch All Strategies
  // -----------------------------
  Stream<List<Map<String, dynamic>>> watchStrategies() {
    return _strategies.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  // -----------------------------
  // Fetch Single Strategy
  // -----------------------------
  Stream<Map<String, dynamic>?> watchStrategy(String strategyId) {
    return _strategies.doc(strategyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    });
  }

  // -----------------------------
  // Internal Helpers
  // -----------------------------
  void _validateTransition(String previous, String next) {
    if (previous == 'retired') {
      throw Exception('Cannot transition from retired state.');
    }

    if (previous == next) {
      throw Exception('Strategy is already in state: $next');
    }

    // Allowed transitions:
    // created → active/experimental
    // active → paused/retired
    // paused → active/retired
    // experimental → paused/retired/active
    final allowed = {
      'active': ['paused', 'retired', 'experimental'],
      'paused': ['active', 'retired'],
      'experimental': ['active', 'paused', 'retired'],
      'created': ['active', 'experimental'],
    };

    final allowedNext = allowed[previous] ?? [];

    if (!allowedNext.contains(next)) {
      throw Exception('Invalid transition: $previous → $next');
    }
  }

  String _eventType(String previous, String next) {
    if (previous == 'created') return 'activated';
    if (next == 'paused') return 'paused';
    if (next == 'active') return 'resumed';
    if (next == 'retired') return 'retired';
    if (next == 'experimental') return 'activated';
    return 'updated';
  }
}
