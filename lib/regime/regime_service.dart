import 'dart:async';

/// Minimal RegimeService stub to provide a current regime stream.
/// This satisfies viewmodel imports and can be expanded to use
/// Firestore or other data sources later.
class RegimeService {
  RegimeService();

  /// Returns a stream that emits the current regime identifier (or null).
  /// Currently emits a single null value. Replace with Firestore listener
  /// when regime collection is available.
  Stream<String?> watchCurrentRegime() {
    return Stream<String?>.value(null);
  }
}
