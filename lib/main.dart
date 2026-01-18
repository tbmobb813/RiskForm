import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    
    // Initialize Hive
    await Hive.initFlutter();
    
    // Open the historical_cache box
    await Hive.openBox('historical_cache');
  } catch (e) {
    // Log initialization error and rethrow to prevent app from starting in invalid state
    debugPrint('Initialization error: $e');
    rethrow;
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
