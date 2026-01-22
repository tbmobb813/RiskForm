import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/services/cheap_options_scanner.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/services/default_options_chain_service.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/scanner_screen.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/small_account_dashboard.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/strategy_dashboard_screen.dart';
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
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/spread_builder_screen.dart';

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
    GoRoute(
      path: '/small_account/spread_builder/:ticker',
      name: 'small_account_spread_builder',
      builder: (context, state) {
        final ticker = state.pathParameters['ticker']!;
        final extra = state.extra;

        final svc = extra is OptionsChainService
            ? extra
            : ProviderScope.containerOf(context).read(defaultOptionsChainServiceProvider);

        return SpreadBuilderScreen(chainService: svc, ticker: ticker);
      },
    ),
    GoRoute(
      path: '/small_account/scanner/:ticker',
      name: 'small_account_scanner',
      builder: (context, state) {
        final ticker = state.pathParameters['ticker']!;
        final extra = state.extra;

        final svc = extra is OptionsChainService
            ? extra
            : ProviderScope.containerOf(context).read(defaultOptionsChainServiceProvider);

        return ScannerScreen(chainService: svc, ticker: ticker);
      },
    ),
    // Self-contained Small Account mode routes
    GoRoute(
      path: '/small_account',
      name: 'small_account_root',
      builder: (context, state) => const SmallAccountDashboard(),
    ),
    GoRoute(
      path: '/small_account/dashboard',
      name: 'small_account_dashboard',
      builder: (context, state) => const SmallAccountDashboard(),
    ),
    GoRoute(
      path: '/small_account/scanner',
      name: 'small_account_scanner_root',
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Scanner')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Open the scanner from the Small Account Dashboard or navigate to /small_account/scanner/<TICKER> with an OptionsChainService provided in navigation extra.'),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/small_account/spread_builder',
      name: 'small_account_spread_builder_root',
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Spread Builder')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Open the spread builder from the Small Account Dashboard or navigate to /small_account/spread_builder/<TICKER> with an OptionsChainService provided in navigation extra.'),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/small_account/strategy_dashboard',
      name: 'small_account_strategy_dashboard',
      builder: (context, state) => const StrategyDashboardScreen(),
    ),
  ],
);