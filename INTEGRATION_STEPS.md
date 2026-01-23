# Small Account Cockpit - Integration Steps

Follow these steps to integrate the cockpit into your RiskForm app.

---

## Step 1: Add Cockpit Route (2 minutes)

### Edit `lib/routing/app_router.dart`

Add the import at the top:

```dart
import '../screens/cockpit/small_account_cockpit_screen.dart';
```

Add the route after line 97 (after the `/behavior` route):

```dart
GoRoute(
  path: '/cockpit',
  name: 'cockpit',
  builder: (context, state) => const SmallAccountCockpitScreen(),
),
```

**Result**: You can now navigate to `/cockpit` in your app.

---

## Step 2: Update Dashboard Navigation (5 minutes)

You have two options:

### Option A: Replace Small Account Mode Entirely (Recommended)

Edit `lib/screens/dashboard/dashboard_screen.dart`:

Find this section (around line 30):

```dart
state.mode == AccountMode.smallAccount
    ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModeSelectorCard(),
          const SizedBox(height: 16),
          SmallAccountDashboardBody(),
          // ...
        ],
      )
```

Replace with:

```dart
state.mode == AccountMode.smallAccount
    ? const SmallAccountCockpitScreen() // NEW UNIFIED COCKPIT
```

**Result**: Small Account mode now shows the cockpit by default.

### Option B: Add as Navigation Button (Keep Both)

If you want to keep the existing small account dashboard and add the cockpit as an option:

Edit `lib/screens/dashboard/dashboard_screen.dart`, add after line 40:

```dart
const SizedBox(height: 16),
Card(
  child: ListTile(
    leading: const Icon(Icons.speed, color: Colors.blue),
    title: const Text('Small Account Cockpit'),
    subtitle: const Text('Unified dashboard with discipline tracking'),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () => context.goNamed('cockpit'),
  ),
),
```

**Result**: Users can access both the old dashboard and new cockpit.

---

## Step 3: Update Journal Entry Model (5 minutes)

### Ensure UID is stored in journal entries

Edit `lib/journal/journal_entry_model.dart`:

Check if `uid` field exists. If not, add it:

```dart
class JournalEntry {
  final String id;
  final String uid; // ADD THIS if not present
  final DateTime createdAt;
  // ... existing fields

  JournalEntry({
    required this.id,
    required this.uid, // ADD THIS
    required this.createdAt,
    // ... existing fields
  });

  factory JournalEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return JournalEntry(
      id: doc.id,
      uid: data['uid'] as String? ?? '', // ADD THIS
      // ... existing fields
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid, // ADD THIS
    // ... existing fields
  };
}
```

### Update journal creation to include UID

Find where you create journal entries (likely in a journal service or controller).

Add the user ID:

```dart
await FirebaseFirestore.instance.collection('journalEntries').add({
  'uid': FirebaseAuth.instance.currentUser!.uid, // ADD THIS LINE
  'strategyId': strategyId,
  'disciplineScore': score,
  'disciplineBreakdown': breakdown,
  'createdAt': FieldValue.serverTimestamp(),
  // ... other fields
});
```

**Result**: Journal entries are now user-specific, enabling proper discipline tracking.

---

## Step 4: Set Up Firestore Security Rules (3 minutes)

### Update Firestore Rules

In Firebase console or `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Journal entries - user-specific
    match /journalEntries/{entryId} {
      allow read, write: if request.auth != null
        && request.resource.data.uid == request.auth.uid;
    }

    // User cockpit data
    match /users/{userId}/cockpit/{document=**} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }

    // User positions
    match /users/{userId}/positions/{positionId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }

    // ... your existing rules
  }
}
```

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

**Result**: Cockpit data is properly secured per-user.

---

## Step 5: Create Test Data (5 minutes)

### Create Sample Journal Entries

Run this code in your app (or Firebase console):

```dart
// Add this as a temporary function in your app
Future<void> createTestJournalData() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final firestore = FirebaseFirestore.instance;

  // Create 5 test journal entries with varying discipline scores
  final testEntries = [
    {'score': 92, 'adherence': 38, 'timing': 32, 'risk': 22},
    {'score': 85, 'adherence': 35, 'timing': 30, 'risk': 20},
    {'score': 78, 'adherence': 32, 'timing': 26, 'risk': 20},
    {'score': 88, 'adherence': 36, 'timing': 30, 'risk': 22},
    {'score': 90, 'adherence': 37, 'timing': 31, 'risk': 22},
  ];

  for (int i = 0; i < testEntries.length; i++) {
    await firestore.collection('journalEntries').add({
      'uid': uid,
      'strategyId': 'CSP',
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
      'notes': 'Test entry ${i + 1}',
      'tags': [],
    });
  }

  print('Created ${testEntries.length} test journal entries');
}

// Call this once from a button or debug screen
```

**Result**: You have test data to verify discipline scoring works.

---

## Step 6: Test Basic Functionality (10 minutes)

### Run the app

```bash
flutter run
```

### Navigate to cockpit

```dart
// In your app, navigate to:
context.goNamed('cockpit');

// Or if using Option A from Step 2:
// Switch to Small Account mode via ModeSelectorCard
```

### Verify these work:

1. **Discipline Header**
   - [ ] Shows discipline score (should be ~87 from test data)
   - [ ] Shows streak count
   - [ ] Displays contextual message

2. **Account Snapshot**
   - [ ] Shows balance from `accountBalanceProvider`
   - [ ] Shows risk deployed
   - [ ] Shows regime (should be "Sideways" placeholder)

3. **Watchlist**
   - [ ] Add a ticker (e.g., "AAPL")
   - [ ] Verify it shows with "N/A" for price/IV
   - [ ] Add 4 more tickers
   - [ ] Try adding 6th (should error)
   - [ ] Remove a ticker

4. **Pull to Refresh**
   - [ ] Pull down to refresh
   - [ ] Verify loading indicator shows
   - [ ] Data reloads

---

## Step 7: Wire Up Journal Blocking (15 minutes)

### Create helper to add pending journals

Create `lib/screens/cockpit/services/pending_journal_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pending_journal_trade.dart';
import '../controllers/cockpit_controller.dart';

class PendingJournalService {
  final Ref ref;

  PendingJournalService(this.ref);

  /// Call this when a position is closed
  Future<void> addPendingJournal({
    required String positionId,
    required String ticker,
    required String strategy,
    required double pnl,
    required bool isPaper,
  }) async {
    final trade = PendingJournalTrade(
      positionId: positionId,
      ticker: ticker,
      strategy: strategy,
      pnl: pnl,
      closedAt: DateTime.now(),
      isPaper: isPaper,
    );

    await ref.read(cockpitControllerProvider.notifier).addPendingJournal(trade);
  }

  /// Call this after journaling is complete
  Future<void> removePendingJournal(String positionId) async {
    await ref.read(cockpitControllerProvider.notifier).removePendingJournal(positionId);
  }
}

final pendingJournalServiceProvider = Provider((ref) => PendingJournalService(ref));
```

### Update your position closing logic

Find where you close positions (likely in a position controller or service).

Add this **after** closing a position:

```dart
// After closing position
final pendingService = ref.read(pendingJournalServiceProvider);
await pendingService.addPendingJournal(
  positionId: position.id,
  ticker: position.ticker,
  strategy: '${position.strategy} ${position.ticker} \$${position.strike.toStringAsFixed(0)}',
  pnl: position.realizedPnl,
  isPaper: position.isPaper,
);
```

### Update journal submission

Find where you save journal entries.

Add this **after** saving:

```dart
// After saving journal entry
final pendingService = ref.read(pendingJournalServiceProvider);
await pendingService.removePendingJournal(positionId);

// Optionally show success message
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Journal saved! You can now open new positions.')),
);
```

### Test blocking behavior

1. Manually add a pending journal:

```dart
// Add this to a debug button
ref.read(cockpitControllerProvider.notifier).addPendingJournal(
  PendingJournalTrade(
    positionId: 'test-123',
    ticker: 'AAPL',
    strategy: 'CSP AAPL $170',
    pnl: 42.50,
    closedAt: DateTime.now(),
  ),
);
```

2. Verify "Required Action" card appears
3. Click "New Trade Plan" button
4. Verify blocking dialog appears
5. Click "Journal Now" on the pending trade
6. (For now, it will just show a toast)
7. Remove pending journal manually
8. Verify card disappears

**Result**: Journal blocking system is working.

---

## Step 8: Connect Navigation (10 minutes)

### Wire up navigation callbacks

Edit `lib/screens/cockpit/small_account_cockpit_screen.dart`:

Find the TODOs and replace with actual navigation:

**Line 43-48** - Journal tap:

```dart
onJournalTap: (trade) {
  // Navigate to journal screen with pre-filled data
  context.goNamed('journal', extra: {
    'positionId': trade.positionId,
    'ticker': trade.ticker,
    'strategy': trade.strategy,
    'pnl': trade.pnl,
  });
},
```

**Line 52-57** - Manage position:

```dart
onManageTap: (position) {
  // Navigate to position management (create this screen if needed)
  context.goNamed('position_details', extra: position);
},
```

**Line 58-63** - Journal and close:

```dart
onJournalAndCloseTap: (position) {
  // Navigate to journal with position pre-filled
  context.goNamed('journal', extra: {
    'positionId': position.id,
    'ticker': position.ticker,
    'strategy': position.displayName,
    'pnl': position.unrealizedPnL,
  });
},
```

**Line 104-108** - Performance:

```dart
onPerformance: () {
  // Navigate to performance/analytics screen
  context.goNamed('performance'); // Create this route if needed
},
```

**Line 109-112** - Behavior:

```dart
onBehavior: () {
  context.goNamed('behavior'); // Already exists!
},
```

**Line 115-120** - New Trade Plan:

```dart
onNewTradePlan: () => _handleNewTradePlan(context, state),
```

(This already calls the handler with blocking logic - no change needed)

### Update journal screen to accept pre-filled data

Edit your journal screen to read `extra` data:

```dart
// In journal_screen.dart or wherever you handle journal creation
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context);
    final extraData = route.extra as Map<String, dynamic>?;

    // Pre-fill form if data provided
    final positionId = extraData?['positionId'] as String?;
    final ticker = extraData?['ticker'] as String?;
    final strategy = extraData?['strategy'] as String?;
    final pnl = extraData?['pnl'] as double?;

    return Scaffold(
      // ... build your form with pre-filled values
    );
  }
}
```

**Result**: All navigation works, journal form is pre-filled from pending trades.

---

## Step 9: Verify Full Workflow (15 minutes)

### End-to-end test:

1. **Open cockpit**
   - Switch to Small Account mode (or navigate to /cockpit)
   - Verify discipline score shows correctly

2. **Close a position** (simulate)
   - Create a test position
   - Close it
   - Verify it appears in "Required Action" card

3. **Try to create new trade**
   - Click "New Trade Plan"
   - Verify blocking dialog appears

4. **Journal the trade**
   - Click "Journal Now" on pending trade
   - Fill out journal (or auto-submit with test data)
   - Verify pending journal disappears

5. **Create new trade** (now allowed)
   - Click "New Trade Plan" again
   - Verify it navigates to planner (no blocking)

6. **Check weekly summary**
   - Scroll to bottom
   - Verify weekly calendar shows trades

**Result**: Full workflow is working!

---

## Step 10: Polish & Deploy (Optional - 30 minutes)

### Customize colors

Edit `lib/screens/cockpit/widgets/discipline_header_card.dart` line 100+:

```dart
case DisciplineLevel.excellent:
  return _ColorScheme(
    backgroundColor: const Color(0xFFECFDF5), // Your brand color
    accentColor: const Color(0xFF10B981),     // Your accent
    textColor: const Color(0xFF065F46),       // Your text color
  );
```

### Adjust discipline thresholds

Edit `lib/screens/cockpit/models/discipline_snapshot.dart` line 45:

```dart
static DisciplineLevel fromScore(int score) {
  if (score >= 90) return DisciplineLevel.excellent; // Change thresholds
  if (score >= 80) return DisciplineLevel.good;
  if (score >= 70) return DisciplineLevel.fair;
  // ...
}
```

### Change watchlist limit

Edit `lib/screens/cockpit/controllers/cockpit_controller.dart` line 128:

```dart
if (state.watchlist.length >= 5) { // Change 5 to your limit
```

### Add analytics tracking

```dart
// Track cockpit opens
await analytics.logEvent(name: 'cockpit_opened');

// Track discipline milestones
if (cleanStreak == 10) {
  await analytics.logEvent(name: 'streak_milestone_10');
}

// Track blocking events
await analytics.logEvent(name: 'trade_blocked_journal_required');
```

---

## Troubleshooting

### "Discipline score shows 0"

**Cause**: No journal entries with `uid` field.

**Fix**: Run Step 5 to create test data, or ensure existing entries have `uid`.

### "Required Action card not appearing"

**Cause**: Pending journals not being added.

**Fix**: Verify Step 7 is implemented - `addPendingJournal` called when closing positions.

### "Watchlist not persisting"

**Cause**: Firestore permissions or user not authenticated.

**Fix**:
1. Check Step 4 Firestore rules are deployed
2. Verify user is logged in: `print(FirebaseAuth.instance.currentUser?.uid)`

### "Import errors"

**Fix**: Ensure all imports are added:

```dart
// In app_router.dart
import '../screens/cockpit/small_account_cockpit_screen.dart';

// In any file using cockpit models
import 'package:riskform/screens/cockpit/models/pending_journal_trade.dart';
import 'package:riskform/screens/cockpit/controllers/cockpit_controller.dart';
```

### "CockpitController not found"

**Fix**: Ensure the provider is imported where you use it:

```dart
import 'package:riskform/screens/cockpit/controllers/cockpit_controller.dart';

// Then access:
final state = ref.watch(cockpitControllerProvider);
```

---

## Success Checklist

Integration is complete when:

- [ ] Cockpit route exists and is navigable
- [ ] Discipline score displays correctly from journal data
- [ ] Watchlist can add/remove tickers (max 5)
- [ ] Test pending journal shows "Required Action" card
- [ ] "New Trade Plan" blocks when pending journals exist
- [ ] Journaling removes pending journal
- [ ] Weekly calendar shows recent trades
- [ ] Navigation works to planner, behavior dashboard
- [ ] Pull-to-refresh updates data
- [ ] Firestore persistence works (close/reopen app)

---

## Next Steps After Integration

1. **User testing** with 3-5 traders
2. **Measure metrics**: Daily opens, journal completion rate, streaks
3. **Iterate** based on feedback
4. **Phase 2**: Add live market data when ready

---

**Estimated Time**: 1-2 hours for basic integration, 3-4 hours including testing

**Questions?** See [small_account_cockpit_implementation.md](docs/small_account_cockpit_implementation.md) for detailed troubleshooting.
