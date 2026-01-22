import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indicates whether Firebase successfully initialized at startup.
/// Main will override this value based on runtime initialization result.
final firebaseAvailableProvider = Provider<bool>((ref) => true);
