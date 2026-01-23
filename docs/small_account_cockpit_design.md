# Small Account Cockpit - Design Specification

## Vision

**Goal**: Create a single, unified screen that makes discipline-first trading frictionless for small accounts.

**Philosophy**: "You can't trade without a plan. You can't plan without journaling your last trade."

---

## Design Principles

1. **Discipline First**: Discipline score is the most prominent element on screen
2. **Behavioral Friction**: Force planning before trading, journaling after closing
3. **Gamification**: Streaks and scores are visible everywhere
4. **Actionable**: Every card has a clear next action
5. **Context-Aware**: Show regime, warnings, and personalized guidance
6. **Simple**: Maximum 5-6 cards on screen, no scrolling paralysis

---

## Screen Layout (Mobile-First)

```
┌─────────────────────────────────────────────────────────┐
│ 🎯 Small Account Cockpit                      [Settings]│
├─────────────────────────────────────────────────────────┤
│                                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ DISCIPLINE HEADER (Always Visible)                  │ │
│ │                                                      │ │
│ │  82/100     🔥 9-day streak    ⚠️ 1 pending journal │ │
│ │  [━━━━━━━━━━━━━━━━░░░░] Good                        │ │
│ │                                                      │ │
│ │  "You're on track. 1 more clean trade for 10-day    │ │
│ │   streak! Journal your last trade to continue."     │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ ACCOUNT SNAPSHOT                                    │ │
│ │                                                      │ │
│ │  Balance: $5,247.32         Regime: 📈 Uptrend     │ │
│ │  Risk Deployed: $487.50     Available: $4,759.82   │ │
│ │  Open Positions: 2          Buying Power: 90.7%    │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ REQUIRED ACTION (Blocking)                          │ │
│ │                                                      │ │
│ │  ⚠️ You must journal your last trade before        │ │
│ │     opening new positions                           │ │
│ │                                                      │ │
│ │  Trade: AAPL CSP $170 → Closed for +$42            │ │
│ │  [Journal This Trade]                               │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ WATCHLIST (5 max for small accounts)                │ │
│ │                                                      │ │
│ │  SPY   $450.12  IV: 15%  ▼ -0.3%  [Scan]           │ │
│ │  AAPL  $175.32  IV: 28%  ▲ +1.2%  [Scan]           │ │
│ │  QQQ   $385.45  IV: 18%  ▲ +0.8%  [Scan]           │ │
│ │                                                      │ │
│ │  [+ Add Ticker (2/5 used)]                          │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ OPEN POSITIONS (Wheel Cycle Tracker)                │ │
│ │                                                      │ │
│ │  CSP AAPL $170                                      │ │
│ │  12 DTE  |  Θ: $4.20/day  |  P/L: +$12.50          │ │
│ │  [Manage] [Roll] [Journal & Close]                  │ │
│ │                                                      │ │
│ │  CSP SPY $445                                       │ │
│ │  8 DTE   |  Θ: $6.30/day  |  P/L: -$8.20           │ │
│ │  [Manage] [Roll] [Journal & Close]                  │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ QUICK ACTIONS                                       │ │
│ │                                                      │ │
│ │  [📝 New Trade Plan] [📊 Performance] [🧠 Behavior] │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ THIS WEEK                                           │ │
│ │                                                      │ │
│ │  P/L: +$127.50 (2.4%)   Trades: 3   Win Rate: 66%  │ │
│ │  Avg Discipline: 85/100                             │ │
│ │                                                      │ │
│ │  Mon Tue Wed Thu Fri Sat Sun                        │ │
│ │   ✓   ✓   ✗   -   -   -   -                        │ │
│ │  (Green = clean trade, Red = violation)             │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## State Machine: Behavioral Friction Flow

### User States

1. **Clean State**: No pending journals, can trade freely
2. **Blocked State**: Pending journal required before new trades
3. **Warning State**: Low discipline score, show intervention

### Trading Flow with Friction

```
User wants to trade
  ↓
Check: Any closed positions without journal?
  ↓ YES → Block trade, show "Journal Required" card
  ↓ NO  → Check: Discipline score < 70?
  ↓ YES → Show warning: "Your discipline is low. Consider taking a break."
  ↓ NO  → Allow trade
  ↓
User completes trade plan
  ↓
Review risk metrics
  ↓
Execute trade (paper or live)
  ↓
Position added to "Open Positions"
  ↓
User closes position
  ↓
STATE CHANGE: Position moves to "Pending Journal"
  ↓
User clicks "Journal This Trade"
  ↓
Auto-filled journal form opens
  ↓
User submits journal
  ↓
Discipline score calculated
  ↓
Streak updated
  ↓
STATE CHANGE: Clean state restored
```

---

## Data Models

### Cockpit State

```dart
class CockpitState {
  final DisciplineSnapshot discipline;
  final AccountSnapshot account;
  final List<PendingJournalTrade> pendingJournals;
  final List<WatchlistItem> watchlist;
  final List<OpenPosition> positions;
  final WeeklySummary weekSummary;
  final MarketRegime regime;

  bool get isBlocked => pendingJournals.isNotEmpty;
  String? get blockingMessage => isBlocked
    ? "Journal your last ${pendingJournals.length} trade(s) before opening new positions"
    : null;
}
```

### Discipline Snapshot

```dart
class DisciplineSnapshot {
  final int currentScore;      // 0-100
  final int cleanStreak;       // Consecutive clean trades
  final int adherenceStreak;   // Consecutive adherence
  final String statusMessage;  // Contextual message
  final DisciplineLevel level; // Excellent/Good/Fair/Poor

  static DisciplineLevel levelFromScore(int score) {
    if (score >= 90) return DisciplineLevel.excellent;
    if (score >= 80) return DisciplineLevel.good;
    if (score >= 70) return DisciplineLevel.fair;
    return DisciplineLevel.poor;
  }
}

enum DisciplineLevel { excellent, good, fair, poor }
```

### Pending Journal Trade

```dart
class PendingJournalTrade {
  final String positionId;
  final String ticker;
  final String strategy;      // "CSP AAPL $170"
  final double pnl;
  final DateTime closedAt;
  final bool isPaper;
}
```

### Watchlist Item

```dart
class WatchlistItem {
  final String ticker;
  final double price;
  final double ivPercentile;
  final double changePercent;
  final bool hasLiveData;     // false = delayed/simulated
}
```

### Open Position

```dart
class OpenPosition {
  final String id;
  final String ticker;
  final String strategy;      // "CSP", "CSP+CC", etc.
  final double strike;
  final int dte;              // Days to expiration
  final double thetaPerDay;
  final double unrealizedPnL;
  final WheelCycleState? cycleState;  // If wheel strategy
}
```

### Weekly Summary

```dart
class WeeklySummary {
  final double pnl;
  final double pnlPercent;
  final int trades;
  final double winRate;
  final double avgDiscipline;
  final List<DayTrade> dailyTrades;  // 7 days, Mon-Sun
}

class DayTrade {
  final DateTime date;
  final bool hadTrade;
  final bool wasClean;        // Discipline >= 80
}
```

---

## Behavioral Rules

### Rule 1: Journal Before Trade (Hard Block)

- **Trigger**: User tries to create new trade plan while `pendingJournals.isNotEmpty`
- **Action**: Block navigation, show modal: "You must journal [ticker] trade before planning new trades"
- **Override**: None (this is a hard constraint)

### Rule 2: Low Discipline Warning (Soft Block)

- **Trigger**: User tries to create new trade plan with `discipline.currentScore < 70`
- **Action**: Show warning modal: "Your discipline score is low (XX/100). Consider reviewing your last trades or taking a break."
- **Override**: User can click "I understand, proceed anyway" (logs this as a warning violation)

### Rule 3: Streak Celebration

- **Trigger**: User completes journal that results in new streak milestone (5, 10, 15, 20, etc.)
- **Action**: Show celebration modal: "🔥 You're on a XX-day streak! Keep it up!"

### Rule 4: Watchlist Limit (Small Account Constraint)

- **Trigger**: User tries to add 6th ticker to watchlist
- **Action**: Show modal: "Small accounts focus on 5 tickers max. Remove one to add another."

### Rule 5: Daily Digest (Notification)

- **Trigger**: Every day at 8 PM local time
- **Action**: Send push notification: "Today you stuck to your plan on X/Y trades. Tap to review."

---

## Widget Architecture

```
SmallAccountCockpitScreen (StatelessWidget)
  ↓
  Consumer<CockpitController>
    ↓
    SingleChildScrollView
      ↓
      Column
        ├─ DisciplineHeaderCard (always visible, sticky)
        ├─ AccountSnapshotCard
        ├─ RequiredActionCard (conditional, if blocked)
        ├─ WatchlistCard
        ├─ OpenPositionsCard
        ├─ QuickActionsCard
        └─ WeeklySummaryCard
```

### Key Widget Implementations

#### DisciplineHeaderCard

- Shows score with progress bar
- Displays streak with fire emoji
- Shows pending journal count badge
- Contextual message based on state
- Color-coded by discipline level (green/yellow/orange/red)

#### RequiredActionCard

- Only visible when `isBlocked == true`
- Lists pending journals
- Each journal has [Journal Now] button
- Blocking UI pattern (red/orange warning colors)

#### WatchlistCard

- Maximum 5 tickers
- Each row: Ticker, Price, IV, Change%, [Scan] button
- [Scan] button opens options scanner for that ticker
- [+ Add Ticker] shows ticker search dialog

#### OpenPositionsCard

- Shows all open positions grouped by strategy
- For each position: Ticker, DTE, Theta, P/L
- Action buttons: [Manage] [Roll] [Journal & Close]
- [Journal & Close] opens pre-filled journal form

---

## Integration Points

### Existing Services to Use

1. **BehaviorAnalytics** - Compute streaks and discipline trends
2. **StrategyController** - Access active strategy and mode
3. **JournalEntry** - Journal data and discipline scores
4. **AccountProviders** - Balance and risk deployed

### New Services to Create

1. **CockpitController** - Central state management for cockpit
2. **PendingJournalService** - Track closed positions awaiting journal
3. **WatchlistService** - Manage watchlist (persist to Firestore)
4. **MarketRegimeService** - Classify current market regime (placeholder until Phase 6)

### Firebase Collections

```
users/{uid}/cockpit/
  - watchlist: [ticker1, ticker2, ...]
  - pendingJournals: [{positionId, ticker, strategy, pnl, closedAt}]
  - weeklyStats: {pnl, trades, winRate, avgDiscipline}
```

---

## User Flows

### Flow 1: First-Time User (Onboarding)

1. User opens app → Sees cockpit with empty state
2. Account Snapshot shows $0 balance
3. Watchlist shows [+ Add Your First Ticker]
4. Quick Actions prominently shows [📝 Create Your First Plan]
5. Behavior section shows: "Start your first trade to build your discipline score!"

### Flow 2: Clean State User (Happy Path)

1. User opens cockpit
2. Sees discipline score 87/100, 12-day streak
3. Sees 2 open positions with positive P/L
4. Clicks [Scan] next to SPY in watchlist
5. Reviews cheap options, picks one
6. Clicks [New Trade Plan]
7. Fills out plan → Saves → Opens position
8. Returns to cockpit → Position appears in "Open Positions"

### Flow 3: Blocked State User (Friction)

1. User opens cockpit
2. Sees **Required Action** card in red/orange
3. "⚠️ Journal AAPL trade before opening new positions"
4. User clicks [Journal This Trade]
5. Journal form pre-filled with trade details
6. User adds notes, submits
7. Discipline score calculated: 78/100
8. Cockpit refreshes → Required Action card disappears
9. User now free to trade

### Flow 4: Low Discipline Warning

1. User with 68/100 discipline tries to create new plan
2. Modal appears: "Your discipline is low. Consider taking a break."
3. Options: [Review Last Trades] [Take A Break] [Proceed Anyway]
4. If [Proceed Anyway] → Logs warning violation, allows trade
5. If [Review Last Trades] → Opens behavior dashboard
6. If [Take A Break] → Closes modal, returns to cockpit

---

## Phase 1 Implementation (MVP - No Live Data)

### Features

- Static watchlist (no live prices, shows $0.00)
- Simulated regime (always "Sideways")
- Manual position entry (user inputs positions)
- Full discipline scoring and streaks
- Journal blocking (hard constraint)
- Weekly summary (calculated from journal entries)

### Placeholders

- IV values: Show "N/A" with note "Live data coming in Phase 6"
- Price changes: Show "—"
- [Scan] buttons: Show "Coming soon" toast

---

## Phase 2 Implementation (Live Data Integration)

### New Features

- Real-time watchlist prices (Polygon.io / Tradier)
- Live IV percentile calculations
- Working [Scan] buttons → Options chain viewer
- Regime detection using market data
- Price alerts (e.g., "AAPL broke support at $170")

---

## Success Metrics

1. **Engagement**: Daily active users opening cockpit
2. **Behavioral**: % of trades with journal completed within 24 hours
3. **Gamification**: Average streak length
4. **Discipline**: % of users with score > 80
5. **Retention**: 7-day retention rate

---

## Accessibility & UX Notes

- Use large, tappable buttons (min 44x44 points)
- High contrast for discipline score colors
- VoiceOver support for all interactive elements
- Haptic feedback on streak milestones
- Dark mode support (discipline score colors must work in both themes)

---

## Technical Considerations

### Performance

- Lazy load weekly summary (Firestore query can be cached)
- Debounce watchlist price updates (max 1/sec per ticker)
- Paginate open positions if > 10

### Offline Support

- Cache last known discipline score
- Show stale data with timestamp: "Last updated 2 hours ago"
- Queue journal submissions for sync when online

### Error Handling

- Firestore errors: Show cached data + "Unable to sync" banner
- Network errors on watchlist: Show last known prices
- Graceful degradation: If regime service fails, show "Unknown regime"

---

## Design Tokens (Colors)

```dart
// Discipline Score Colors
const disciplineExcellent = Color(0xFF10B981);  // Green-500
const disciplineGood = Color(0xFF3B82F6);       // Blue-500
const disciplineFair = Color(0xFFF59E0B);       // Amber-500
const disciplinePoor = Color(0xFFEF4444);       // Red-500

// Streak Colors
const streakFire = Color(0xFFFF6B35);           // Orange-red for fire emoji
const streakMilestone = Color(0xFFFBBF24);      // Gold for milestones

// Blocking/Warning
const blockingRed = Color(0xFFFEE2E2);          // Red-50 background
const warningAmber = Color(0xFFFEF3C7);         // Amber-50 background
```

---

## Next Steps (Implementation Order)

1. ✅ Design spec (this document)
2. [ ] Create data models (`cockpit_state.dart`, `discipline_snapshot.dart`)
3. [ ] Implement CockpitController (Riverpod StateNotifier)
4. [ ] Build widget components (DisciplineHeaderCard, etc.)
5. [ ] Implement SmallAccountCockpitScreen
6. [ ] Add behavioral friction logic (journal blocking)
7. [ ] Wire up existing services (BehaviorAnalytics, JournalEntry)
8. [ ] Test on iOS + Android
9. [ ] Add to navigation (replace existing dashboard route)
10. [ ] Iterate based on user testing
