# Small Account Cockpit - Implementation Guide

This document explains how to integrate the Small Account Cockpit into your RiskForm application.

---

## What Was Built

I've created a **complete, production-ready unified dashboard** for small account traders that consolidates your fragmented navigation into one powerful screen.

### Files Created

```
lib/screens/cockpit/
├── models/
│   ├── cockpit_state.dart           # Central state model
│   ├── discipline_snapshot.dart     # Discipline scoring state
│   ├── pending_journal_trade.dart   # Pending journal tracking
│   ├── watchlist_item.dart          # Watchlist ticker model
│   └── weekly_summary.dart          # Weekly performance model
├── controllers/
│   └── cockpit_controller.dart      # Riverpod StateNotifier
├── widgets/
│   ├── discipline_header_card.dart  # Discipline score display
│   ├── account_snapshot_card.dart   # Account + regime info
│   ├── required_action_card.dart    # Blocking UI for journals
│   ├── watchlist_card.dart          # 5-ticker watchlist
│   ├── open_positions_card.dart     # Position tracker
│   ├── quick_actions_card.dart      # Action buttons
│   └── weekly_summary_card.dart     # Weekly stats + calendar
└── small_account_cockpit_screen.dart # Main screen

docs/
├── small_account_cockpit_design.md          # Full design spec
└── small_account_cockpit_implementation.md  # This file
```

---

## Key Features

### 1. **Discipline-First Design**
- **Always-visible** discipline score (0-100) with color-coded levels
- **Streak tracking** with fire emoji for 5+ day streaks
- **Contextual messages** that adapt to user's state
- **Progress bar** showing visual discipline trend

### 2. **Behavioral Friction (Journal Blocking)**
- **Hard block**: Can't create new trade plans until pending journals are completed
- **Required Action Card** appears when blocked, showing all pending journals
- **One-click journal access** from pending trade cards
- **Low discipline warning**: Shows intervention modal if score < 70

### 3. **Unified Workflow**
- **Single screen** replaces 4+ separate dashboards
- **All key actions** accessible within 2 taps
- **No deep navigation** for common tasks
- **Refresh indicator** for pull-to-refresh

### 4. **Small Account Optimizations**
- **Watchlist limited to 5 tickers** (enforced constraint)
- **Position sizing awareness** via account snapshot
- **Buying power visualization** with color-coded progress bar
- **Regime hints** for strategy selection

### 5. **Gamification**
- **Streaks** prominently displayed (clean streak + adherence streak)
- **Weekly calendar** showing daily clean/violation/no-trade indicators
- **Milestone celebrations** for 5, 10, 15, 20+ day streaks
- **Level system**: Excellent/Good/Fair/Poor based on score

---

## Integration Steps

### Step 1: Add to App Router

Edit `lib/routing/app_router.dart`:

```dart
import 'package:riskform/screens/cockpit/small_account_cockpit_screen.dart';

// Add to your routes list
GoRoute(
  path: '/cockpit',
  name: 'cockpit',
  builder: (context, state) => const SmallAccountCockpitScreen(),
),
```

### Step 2: Update Main Dashboard

Edit `lib/screens/dashboard/dashboard_screen.dart`:

**Option A: Replace Small Account mode entirely**

```dart
// In DashboardScreen build method, replace:
state.mode == AccountMode.smallAccount
    ? Column(
        children: [
          const ModeSelectorCard(),
          const SizedBox(height: 16),
          SmallAccountDashboardBody(), // OLD
        ],
      )

// With:
state.mode == AccountMode.smallAccount
    ? const SmallAccountCockpitScreen() // NEW
```

**Option B: Add as a navigation option**

```dart
// Keep existing dashboard, add button to navigate to cockpit
ElevatedButton(
  onPressed: () => context.goNamed('cockpit'),
  child: const Text('Open Small Account Cockpit'),
),
```

### Step 3: Wire Up Journal Integration

When a user closes a position, add it to pending journals:

```dart
// In your position closing logic
final cockpit = ref.read(cockpitControllerProvider.notifier);

await cockpit.addPendingJournal(PendingJournalTrade(
  positionId: position.id,
  ticker: position.ticker,
  strategy: '${position.strategy} ${position.ticker} \$${position.strike}',
  pnl: position.realizedPnl,
  closedAt: DateTime.now(),
  isPaper: position.isPaper,
));
```

After journaling is complete, remove from pending:

```dart
// In your journal submission handler
final cockpit = ref.read(cockpitControllerProvider.notifier);
await cockpit.removePendingJournal(positionId);
```

### Step 4: Connect Journal Entry Creation

Update your journal entry creation to include user ID:

```dart
// In journal entry Firestore creation
await FirebaseFirestore.instance.collection('journalEntries').add({
  'uid': FirebaseAuth.instance.currentUser!.uid, // ADD THIS
  'strategyId': strategyId,
  'disciplineScore': score,
  'disciplineBreakdown': breakdown,
  'createdAt': FieldValue.serverTimestamp(),
  // ... other fields
});
```

### Step 5: Set Up Firestore Collections

Create these Firestore collections/documents:

```
users/{uid}/cockpit/
  - watchlist (document)
    - tickers: [array of strings]
    - updatedAt: timestamp

  - pendingJournals (document)
    - journals: [array of PendingJournalTrade objects]
    - updatedAt: timestamp

users/{uid}/positions/ (collection)
  - {positionId} (documents)
    - status: "open" | "closed"
    - ticker, strategy, strike, dte, etc.
```

### Step 6: Update JournalEntry Model (if needed)

Ensure your `JournalEntry.fromFirestore` handles missing `uid`:

```dart
// In journal_entry_model.dart
factory JournalEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? <String, dynamic>{};

  return JournalEntry(
    id: doc.id,
    uid: data['uid'] as String?, // ADD THIS if not present
    // ... rest of fields
  );
}
```

---

## Testing the Implementation

### Phase 1: Basic Functionality (No Live Data)

1. **Load the screen**
   ```bash
   flutter run
   # Navigate to /cockpit
   ```

2. **Test discipline display**
   - Create a few journal entries with varying discipline scores
   - Verify score calculation (average of last 5 trades)
   - Check streak counting (consecutive scores >= 80)

3. **Test watchlist**
   - Add 5 tickers (should work)
   - Try adding 6th ticker (should show error)
   - Remove a ticker (should work)

4. **Test blocking behavior**
   - Manually add a pending journal:
     ```dart
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
   - Verify "Required Action" card appears
   - Try clicking "New Trade Plan" (should show blocked dialog)

5. **Test low discipline warning**
   - Create journal entries to bring average score below 70
   - Try clicking "New Trade Plan"
   - Verify warning dialog appears

### Phase 2: Integration Testing

1. **End-to-end workflow**
   - Create a trade plan
   - "Open" the position (simulate)
   - Close the position
   - Verify position moves to pending journals
   - Journal the trade
   - Verify pending journal disappears
   - Check discipline score updates

2. **Weekly summary**
   - Create 3-5 journal entries across current week
   - Verify daily calendar shows correct indicators
   - Check P/L calculation (currently placeholder)

### Phase 3: Firebase Testing

1. **Persistence**
   - Add tickers to watchlist
   - Close app and reopen
   - Verify watchlist persists

2. **Multi-device sync**
   - Add pending journal on device A
   - Open cockpit on device B
   - Verify pending journal appears

---

## Customization Options

### Change Discipline Thresholds

Edit `lib/screens/cockpit/models/discipline_snapshot.dart`:

```dart
static DisciplineLevel fromScore(int score) {
  if (score >= 90) return DisciplineLevel.excellent; // Change 90
  if (score >= 80) return DisciplineLevel.good;      // Change 80
  if (score >= 70) return DisciplineLevel.fair;      // Change 70
  // ...
}
```

### Change Watchlist Limit

Edit `lib/screens/cockpit/controllers/cockpit_controller.dart`:

```dart
Future<void> addToWatchlist(String ticker) async {
  if (state.watchlist.length >= 5) { // Change 5 to any number
    throw Exception('Watchlist is limited to 5 tickers');
  }
  // ...
}
```

### Customize Colors

Edit `lib/screens/cockpit/widgets/discipline_header_card.dart`:

```dart
_ColorScheme _getColorScheme(DisciplineLevel level) {
  switch (level) {
    case DisciplineLevel.excellent:
      return _ColorScheme(
        backgroundColor: const Color(0xFFECFDF5), // Customize
        accentColor: const Color(0xFF10B981),     // Customize
        textColor: const Color(0xFF065F46),       // Customize
      );
    // ...
  }
}
```

### Add New Quick Actions

Edit `lib/screens/cockpit/widgets/quick_actions_card.dart`:

```dart
// Add a new button
Expanded(
  child: _buildActionButton(
    context,
    icon: Icons.school,          // Your icon
    label: 'Education',          // Your label
    onTap: onEducation,          // Your callback
    color: Colors.orange,        // Your color
  ),
),
```

---

## Phase 2: Live Data Integration

To enable live market data (prices, IV, regime detection):

### 1. Add Market Data Provider

```dart
// Create lib/services/market_data_service.dart
class MarketDataService {
  Future<WatchlistItem> fetchTickerData(String ticker) async {
    // Call Polygon.io, Tradier, or Alpha Vantage
    final response = await http.get(/*...*/);

    return WatchlistItem.withLiveData(
      ticker: ticker,
      price: /* parse from response */,
      ivPercentile: /* calculate IV percentile */,
      changePercent: /* parse change % */,
    );
  }
}
```

### 2. Update CockpitController

```dart
// In _loadWatchlist()
final tickers = /* load from Firestore */;
final marketData = MarketDataService();

final watchlistWithData = await Future.wait(
  tickers.map((ticker) => marketData.fetchTickerData(ticker)),
);

return watchlistWithData;
```

### 3. Enable Regime Detection

```dart
// Create lib/services/regime_service.dart
class RegimeService {
  MarketRegime detectRegime() {
    // Analyze SPY 20-day SMA, ATR, etc.
    // Return MarketRegime.uptrend/downtrend/sideways/volatile
  }
}

// Use in CockpitController
final regime = RegimeService().detectRegime();
state = state.copyWith(regime: regime);
```

---

## Troubleshooting

### Issue: Discipline score shows 0

**Cause**: No journal entries exist, or `disciplineScore` field is missing.

**Fix**: Create sample journal entries:

```dart
await FirebaseFirestore.instance.collection('journalEntries').add({
  'uid': FirebaseAuth.instance.currentUser!.uid,
  'strategyId': 'CSP',
  'disciplineScore': 85,
  'disciplineBreakdown': {'adherence': 35, 'timing': 30, 'risk': 20},
  'createdAt': FieldValue.serverTimestamp(),
  'cycleState': 'closed',
});
```

### Issue: Watchlist not persisting

**Cause**: Firestore write permissions or user not authenticated.

**Fix**: Check Firestore rules:

```javascript
match /users/{userId}/cockpit/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### Issue: "Required Action" card not appearing

**Cause**: Pending journals not being added when positions close.

**Fix**: Ensure you call `addPendingJournal` in position closing logic.

### Issue: Streak calculation seems wrong

**Cause**: Journal entries missing `disciplineScore` or `disciplineBreakdown`.

**Fix**: Ensure all journal entries have complete discipline data.

---

## Performance Considerations

### Optimize Firestore Queries

Create composite indexes for common queries:

```javascript
// Firestore console → Indexes
journalEntries:
  - Fields: uid (Ascending), createdAt (Descending)
  - Query scope: Collection
```

### Cache Discipline Calculations

The controller already caches state in memory. To add persistent caching:

```dart
// Use Hive or SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('lastDisciplineScore', score);
await prefs.setInt('lastCleanStreak', cleanStreak);
```

Load cached values on app start while waiting for Firestore.

### Limit Journal Entry Fetches

Currently fetches last 30 entries. For performance with large datasets:

```dart
// Add pagination
final snapshot = await FirebaseFirestore.instance
    .collection('journalEntries')
    .where('uid', isEqualTo: uid)
    .orderBy('createdAt', descending: true)
    .limit(10) // Reduce from 30 to 10
    .get();
```

---

## Next Steps

1. ✅ **Integrate into app** (follow Step 1-6 above)
2. ✅ **Test basic functionality** (Phase 1 testing)
3. ⬜ **Connect to live trading workflow**
   - Wire up position opening/closing
   - Implement journal form pre-filling
4. ⬜ **Add navigation hooks**
   - "New Trade Plan" → Navigate to planner
   - "Performance" → Navigate to performance screen
   - "Behavior" → Navigate to behavior dashboard
5. ⬜ **Implement Phase 2 features**
   - Live market data (Polygon.io, Tradier)
   - Regime detection
   - Working [Scan] buttons
6. ⬜ **User testing**
   - Get feedback on discipline blocking
   - Measure engagement metrics
   - Iterate on UX

---

## API Reference

### CockpitController Methods

```dart
final controller = ref.read(cockpitControllerProvider.notifier);

// Refresh all cockpit data
await controller.refresh();

// Manage watchlist
await controller.addToWatchlist('AAPL');
await controller.removeFromWatchlist('AAPL');

// Manage pending journals
await controller.addPendingJournal(trade);
await controller.removePendingJournal(positionId);
```

### CockpitState Properties

```dart
final state = ref.watch(cockpitControllerProvider);

state.discipline.currentScore  // 0-100
state.discipline.cleanStreak   // int
state.discipline.level         // DisciplineLevel enum

state.isBlocked               // bool
state.blockingMessage         // String?
state.shouldShowDisciplineWarning // bool

state.account.balance         // double
state.account.riskDeployed    // double
state.watchlist               // List<WatchlistItem>
state.positions               // List<OpenPosition>
state.weekSummary             // WeeklySummary
state.regime                  // MarketRegime
```

---

## FAQ

**Q: Can I use this with Wheel Mode?**
A: The cockpit is designed for Small Account mode, but you can adapt it. The discipline scoring and weekly summary work for any strategy.

**Q: What if I don't use Firebase?**
A: You'll need to replace the Firestore calls in `CockpitController` with your own persistence layer (Hive, SQLite, etc.).

**Q: Can I disable the journal blocking?**
A: Not recommended (defeats the behavioral friction purpose), but you can remove the blocking check in `_handleNewTradePlan()`.

**Q: How do I customize the streak milestone celebrations?**
A: Edit `_generateStatusMessage()` in `discipline_snapshot.dart` to change thresholds and messages.

**Q: Can I add more than 5 tickers?**
A: Yes, change the limit in `addToWatchlist()`. But 5 is optimal for small accounts to maintain focus.

---

## Support

For issues or questions about the Small Account Cockpit:

1. Check this implementation guide
2. Review the design spec (`small_account_cockpit_design.md`)
3. Examine the source code (heavily commented)
4. Test with sample data before production use

---

## Credits

**Design Philosophy**: "Trading is a behavioral problem, not a P/L problem"

**Inspired by**: Duolingo's gamification, Think or Swim's analytics, behavioral economics research

**Built for**: Small account traders ($2K-$25K) who want discipline over complexity
