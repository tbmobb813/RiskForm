import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // On web we must provide FirebaseOptions when creating the default app.
    if (kIsWeb) {
      // `DefaultFirebaseOptions.currentPlatform` is generated and non-null for supported
      // platforms; the previous null-check is unnecessary and caused analyzer warnings.
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } else {
      await Firebase.initializeApp();
    }

    // Initialize Hive
    await Hive.initFlutter();
    
    // Open the historical_cache box
    await Hive.openBox(kHistoricalCacheBox);
  } catch (e) {
    // Log initialization error and rethrow to prevent app from starting in invalid state
    debugPrint('Initialization error: $e');
    rethrow;
  }
  
  runApp(const ProviderScope(child: App()));
}
