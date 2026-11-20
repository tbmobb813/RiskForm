import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Event names used for the Phase 1 launch gate (see ROADMAP.md).
///
/// "Weekly engaged" = a user who fires [simRun] or [regimeReplayRun] in two or
/// more distinct weeks. No account is required for any of these events, so the
/// gate measures real simulator usage, not just signups.
class AnalyticsEvents {
  static const simRun = 'sim_run';
  static const regimeReplayRun = 'regime_replay_run';
  static const strategyCompare = 'strategy_compare';
  static const journalEntryCreated = 'journal_entry_created';
  static const importCsv = 'import_csv';
  // Sign-up uses Firebase's standard `sign_up` event via logSignUp.
}

/// Fire-and-forget analytics. Never throws and never blocks the UI: if
/// Firebase is unavailable (desktop dev builds, tests, init failure) or the web
/// app has no measurementId configured, every call is a silent no-op.
class AnalyticsService {
  AnalyticsService._();

  static Future<void> log(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Analytics event "$name" skipped: $e');
    }
  }

  static Future<void> logSignUp() async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
    } catch (e) {
      debugPrint('Analytics sign_up skipped: $e');
    }
  }
}
