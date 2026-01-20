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
      final opts = DefaultFirebaseOptions.currentPlatform;
      if (opts == null) {
        throw FlutterError(
          'Missing Firebase web configuration. Generate firebase_options.dart with the FlutterFire CLI:\n'
          '  dart pub global activate flutterfire_cli && flutterfire configure\n'
          'Or run: flutter pub run flutterfire_cli configure'
        );
      }
      await Firebase.initializeApp(options: opts);
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
