import 'package:go_router/go_router.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/planner//strategy_selector/strategy_selector_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../journal/journal_list_screen.dart';
import '../screens/backtest/cloud_job_status_screen.dart';
import '../screens/backtest/cloud_backtest_result_screen.dart';
import '../screens/backtest/cloud_backtest_history_screen.dart';

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
    GoRoute(
      path: '/journal/firestore',
      name: 'journalFirestore',
      builder: (context, state) => const JournalListScreen(),
    ),
    // Cloud Backtest Routes
    GoRoute(
      path: '/cloud/job/:jobId',
      name: 'cloudJobStatus',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId']!;
        return CloudJobStatusScreen(jobId: jobId);
      },
    ),
    GoRoute(
      path: '/cloud/result/:jobId',
      name: 'cloudResult',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId']!;
        return CloudBacktestResultScreen.fromJobId(jobId: jobId);
      },
    ),
    GoRoute(
      path: '/cloud/history/:userId',
      name: 'cloudHistory',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return CloudBacktestHistoryScreen(userId: userId);
      },
    ),
  ],
);