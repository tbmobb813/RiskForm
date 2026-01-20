import 'package:go_router/go_router.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/planner/strategy_selector/strategy_selector_screen.dart';
import '../screens/planner/trade_planner/trade_planner_screen.dart';
import '../screens/planner/payoff/payoff_screen.dart';
import '../screens/planner/risk_summary/risk_summary_screen.dart';
import '../screens/planner/save_plan/save_plan_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../journal/journal_list_screen.dart';
import '../screens/backtest/cloud_job_status_screen.dart';
import '../screens/backtest/cloud_backtest_result_screen.dart';
import '../screens/backtest/cloud_backtest_history_screen.dart';
import '../behavior/behavior_dashboard_screen.dart';

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
      path: '/trade-planner',
      name: 'trade_planner',
      builder: (context, state) => const TradePlannerScreen(),
    ),
    GoRoute(
      path: '/payoff',
      name: 'payoff',
      builder: (context, state) => const PayoffScreen(),
    ),
    GoRoute(
      path: '/risk-summary',
      name: 'risk_summary',
      builder: (context, state) => const RiskSummaryScreen(),
    ),
    GoRoute(
      path: '/save-plan',
      name: 'save_plan',
      builder: (context, state) => const SavePlanScreen(),
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
    GoRoute(
      path: '/behavior',
      name: 'behavior',
      builder: (context, state) => const BehaviorDashboardScreen(),
    ),
  ],
);