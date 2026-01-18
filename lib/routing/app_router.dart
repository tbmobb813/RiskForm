import 'package:go_router/go_router.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/planner//strategy_selector/strategy_selector_screen.dart';
import '../screens/journal/journal_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/planner',
      name: 'planner',
      builder: (context, state) => const StrategySelectorScreen(),
    ),
    GoRoute(
      path: '/journal',
      name: 'journal',
      builder: (context, state) => const JournalScreen(),
    ),
  ],
);