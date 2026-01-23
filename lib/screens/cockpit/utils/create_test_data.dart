import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility to create test journal data for cockpit testing
///
/// Usage:
/// ```dart
/// await CockpitTestData.createTestJournals();
/// ```
class CockpitTestData {
  /// Create 10 test journal entries with varying discipline scores
  static Future<void> createTestJournals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User must be authenticated to create test data');
    }

    final firestore = FirebaseFirestore.instance;

    // Test entries with varying discipline scores
    final testEntries = [
      {'score': 92, 'adherence': 38, 'timing': 32, 'risk': 22, 'strategy': 'CSP', 'notes': 'Excellent execution, followed plan perfectly'},
      {'score': 85, 'adherence': 35, 'timing': 30, 'risk': 20, 'strategy': 'CSP', 'notes': 'Good trade, slight timing issue'},
      {'score': 88, 'adherence': 36, 'timing': 30, 'risk': 22, 'strategy': 'Debit Spread', 'notes': 'Solid adherence to plan'},
      {'score': 78, 'adherence': 32, 'timing': 26, 'risk': 20, 'strategy': 'CSP', 'notes': 'Timing was off, but stuck to risk limits'},
      {'score': 90, 'adherence': 37, 'timing': 31, 'risk': 22, 'strategy': 'Covered Call', 'notes': 'Perfect execution'},
      {'score': 82, 'adherence': 34, 'timing': 28, 'risk': 20, 'strategy': 'CSP', 'notes': 'Good discipline overall'},
      {'score': 75, 'adherence': 31, 'timing': 24, 'risk': 20, 'strategy': 'Debit Spread', 'notes': 'Could improve timing'},
      {'score': 88, 'adherence': 36, 'timing': 30, 'risk': 22, 'strategy': 'CSP', 'notes': 'Strong adherence'},
      {'score': 91, 'adherence': 37, 'timing': 32, 'risk': 22, 'strategy': 'Iron Condor', 'notes': 'Excellent risk management'},
      {'score': 86, 'adherence': 35, 'timing': 29, 'risk': 22, 'strategy': 'CSP', 'notes': 'Solid trade, minor timing delay'},
    ];

    print('Creating ${testEntries.length} test journal entries...');

    for (int i = 0; i < testEntries.length; i++) {
      await firestore.collection('journalEntries').add({
        'uid': uid,
        'strategyId': testEntries[i]['strategy'],
        'disciplineScore': testEntries[i]['score'],
        'disciplineBreakdown': {
          'adherence': testEntries[i]['adherence'],
          'timing': testEntries[i]['timing'],
          'risk': testEntries[i]['risk'],
        },
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: testEntries.length - i)),
        ),
        'cycleState': 'closed',
        'notes': testEntries[i]['notes'],
        'tags': i % 3 == 0 ? ['small-account', 'disciplined'] : ['small-account'],
      });
    }

    print('✅ Created ${testEntries.length} test journal entries');
    print('Average discipline score: ${testEntries.map((e) => e['score'] as int).reduce((a, b) => a + b) ~/ testEntries.length}');
    print('Expected clean streak: ${_countCleanStreak(testEntries)}');
  }

  static int _countCleanStreak(List<Map<String, dynamic>> entries) {
    int streak = 0;
    for (final entry in entries.reversed) {
      if ((entry['score'] as int) >= 80) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Create a test pending journal (for testing blocking behavior)
  static Future<void> createTestPendingJournal() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User must be authenticated to create test data');
    }

    final firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(uid).collection('cockpit').doc('pendingJournals').set({
      'journals': [
        {
          'positionId': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'ticker': 'AAPL',
          'strategy': 'CSP AAPL \$170',
          'pnl': 42.50,
          'closedAt': DateTime.now().toIso8601String(),
          'isPaper': true,
        },
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Created test pending journal');
    print('You should now see "Required Action" card in cockpit');
  }

  /// Create test watchlist
  static Future<void> createTestWatchlist() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User must be authenticated to create test data');
    }

    final firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(uid).collection('cockpit').doc('watchlist').set({
      'tickers': ['SPY', 'QQQ', 'AAPL'],
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Created test watchlist with SPY, QQQ, AAPL');
  }

  /// Create all test data at once
  static Future<void> createAllTestData() async {
    print('Creating all test data for Small Account Cockpit...\n');

    await createTestJournals();
    print('');

    await createTestWatchlist();
    print('');

    print('✅ All test data created successfully!');
    print('\nNext steps:');
    print('1. Navigate to /cockpit');
    print('2. Verify discipline score shows ~86/100');
    print('3. Verify watchlist shows SPY, QQQ, AAPL');
    print('4. Pull to refresh to update data');
    print('\nTo test blocking:');
    print('await CockpitTestData.createTestPendingJournal();');
  }

  /// Clear all test data
  static Future<void> clearAllTestData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User must be authenticated');
    }

    final firestore = FirebaseFirestore.instance;

    // Delete journal entries
    final journals = await firestore.collection('journalEntries').where('uid', isEqualTo: uid).get();
    for (final doc in journals.docs) {
      await doc.reference.delete();
    }

    // Delete cockpit data
    await firestore.collection('users').doc(uid).collection('cockpit').doc('watchlist').delete();
    await firestore.collection('users').doc(uid).collection('cockpit').doc('pendingJournals').delete();

    print('✅ Cleared all test data');
  }
}
