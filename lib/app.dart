import 'package:flutter/material.dart';
import 'routing/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Options Planner',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: appRouter,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      cardColor: const Color(0xFF1A1A1A),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}