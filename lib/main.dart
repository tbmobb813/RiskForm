import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/firebase/firebase_dev.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  var firebaseInitialized = true;
  try {
    // Use generated platform options for all platforms where available. Some
    // desktop platforms may not have a native Firebase plugin registered;
    // initialize safely and continue if initialization fails in development.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Initialize Hive
    await Hive.initFlutter();
    
    // Open the historical_cache box
    await Hive.openBox(kHistoricalCacheBox);
  } catch (e, st) {
    // Log initialization error but do not crash the app on desktop when the
    // native Firebase implementation isn't available (common in local builds).
    debugPrint('Firebase initialization error (continuing without Firebase): $e');
    debugPrintStack(stackTrace: st);
    firebaseInitialized = false;
  }
  
  runApp(ProviderScope(overrides: [
    firebaseAvailableProvider.overrideWithValue(firebaseInitialized),
  ], child: const App()));
}
