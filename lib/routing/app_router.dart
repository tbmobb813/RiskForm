import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../behavior/behavior_dashboard_screen.dart';
import '../journal/journal_list_screen.dart';
import '../models/signal_planner_preset.dart';
import '../screens/backtest/cloud_backtest_history_screen.dart';
import '../screens/backtest/cloud_backtest_result_screen.dart';
import '../screens/backtest/cloud_job_status_screen.dart';
import '../screens/best_opps/best_opps_screen.dart';
import '../screens/cockpit/debug/cockpit_debug_screen.dart';
import '../screens/cockpit/small_account_cockpit_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/import/import_screen.dart';
import '../screens/journal/attach_screenshot_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../screens/planner/payoff/payoff_screen.dart';
import '../screens/planner/risk_summary/risk_summary_screen.dart';
import '../screens/planner/save_plan/save_plan_screen.dart';
import '../screens/planner/strategy_selector/strategy_selector_screen.dart';
import '../screens/planner/trade_planner/trade_planner_screen.dart';
import '../screens/signals/signal_engine_screen.dart';
import 'app_shell.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/diagonal_builder_screen.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/scanner_screen.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/small_account_dashboard.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/spread_builder_screen.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/strategy_dashboard_screen.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/services/cheap_options_scanner.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/services/default_options_chain_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        // ── Branch 0 · Home ───────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),

        // ── Branch 1 · Cockpit ────────────────────────────────────────────
        StatefulShellBranch(
          initialLocation: '/cockpit',
          routes: [
            GoRoute(
              path: '/cockpit',
              name: 'cockpit',
              builder: (context, state) => const SmallAccountCockpitScreen(),
              routes: [
                GoRoute(
                  path: 'debug',
                  name: 'cockpit_debug',
                  builder: (context, state) => const CockpitDebugScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/behavior',
              name: 'behavior',
              builder: (context, state) => const BehaviorDashboardScreen(),
            ),
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
              path: '/small_account/strategy_dashboard',
              name: 'small_account_strategy_dashboard',
              builder: (context, state) => const StrategyDashboardScreen(),
            ),
            GoRoute(
              path: '/small_account/scanner',
              name: 'small_account_scanner_root',
              builder: (context, state) => Scaffold(
                appBar: AppBar(title: const Text('Scanner')),
                body: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Open the scanner from the Small Account Dashboard.',
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/small_account/scanner/:ticker',
              name: 'small_account_scanner',
              builder: (context, state) {
                final ticker = state.pathParameters['ticker']!;
                final svc = state.extra is OptionsChainService
                    ? state.extra as OptionsChainService
                    : ProviderScope.containerOf(
                        context,
                      ).read(defaultOptionsChainServiceProvider);
                return ScannerScreen(chainService: svc, ticker: ticker);
              },
            ),
            GoRoute(
              path: '/small_account/spread_builder',
              name: 'small_account_spread_builder_root',
              builder: (context, state) => Scaffold(
                appBar: AppBar(title: const Text('Spread Builder')),
                body: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Open the spread builder from the Small Account Dashboard.',
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/small_account/spread_builder/:ticker',
              name: 'small_account_spread_builder',
              builder: (context, state) {
                final ticker = state.pathParameters['ticker']!;
                final svc = state.extra is OptionsChainService
                    ? state.extra as OptionsChainService
                    : ProviderScope.containerOf(
                        context,
                      ).read(defaultOptionsChainServiceProvider);
                return SpreadBuilderScreen(chainService: svc, ticker: ticker);
              },
            ),
            GoRoute(
              path: '/small_account/diagonal_builder/:ticker',
              name: 'small_account_diagonal_builder',
              builder: (context, state) {
                final ticker = state.pathParameters['ticker']!;
                final svc = state.extra is OptionsChainService
                    ? state.extra as OptionsChainService
                    : ProviderScope.containerOf(
                        context,
                      ).read(defaultOptionsChainServiceProvider);
                return DiagonalBuilderScreen(chainService: svc, ticker: ticker);
              },
            ),
          ],
        ),

        // ── Branch 2 · Journal ────────────────────────────────────────────
        StatefulShellBranch(
          initialLocation: '/journal',
          routes: [
            GoRoute(
              path: '/journal',
              name: 'journal',
              builder: (context, state) => const JournalScreen(),
              routes: [
                GoRoute(
                  path: 'firestore',
                  name: 'journalFirestore',
                  builder: (context, state) => const JournalListScreen(),
                ),
                GoRoute(
                  path: 'attach_screenshot',
                  name: 'attach_screenshot',
                  builder: (context, state) => const AttachScreenshotScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Branch 3 · Analyze ────────────────────────────────────────────
        StatefulShellBranch(
          initialLocation: '/signals',
          routes: [
            GoRoute(
              path: '/signals',
              name: 'signal_engine',
              builder: (context, state) => const SignalEngineScreen(),
            ),
            GoRoute(
              path: '/best-opps',
              name: 'best_opps',
              builder: (context, state) => const BestOppsScreen(),
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
          ],
        ),

        // ── Branch 4 · Tools ──────────────────────────────────────────────
        StatefulShellBranch(
          initialLocation: '/planner',
          routes: [
            GoRoute(
              path: '/planner',
              name: 'planner',
              builder: (context, state) => StrategySelectorScreen(
                preset: state.extra is SignalPlannerPreset
                    ? state.extra as SignalPlannerPreset
                    : null,
              ),
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
              path: '/import',
              name: 'import_trades',
              builder: (context, state) => const ImportScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
