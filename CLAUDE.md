# CLAUDE.md - RiskForm Project Guide

This file provides guidance to Claude Code when working with the RiskForm codebase.

## Project Identity

**Name**: RiskForm  
**Type**: Cross-platform options trading platform (Flutter)  
**Target Users**: Small account traders ($2K-$25K)  
**Core Philosophy**: "Trading is a behavioral problem, not a P/L problem"

**NOT StatusWatch** - If you see references to StatusWatch in global CLAUDE.md, ignore them for this project.

---

## What RiskForm Actually Is

RiskForm is a **discipline-first trading platform** that combines:
- **Gamification**: Discipline scores, streaks, levels, milestone celebrations
- **Behavioral Friction**: Journal blocking (can't trade without journaling)
- **Small Account Tools**: Watchlist limited to 5 tickers, position sizing, spread builders
- **Real-Time Accountability**: Streak tracking, weekly calendars, regime hints

**Think "Duolingo for options trading"** - not a complexity beast like Think or Swim.

---

## Current State (Phase 6)

### ✅ What's Built
- **Small Account Cockpit**: Unified discipline-first dashboard (`lib/screens/cockpit/`)
- **Trade Planner**: Multi-step workflow (strategy → parameters → payoff → risk → save)
- **Journal System**: Automated discipline scoring with Firestore sync
- **Wheel Strategy Engine**: CSP → Assignment → CC → Called Away state machine
- **Backtest Engine**: Realistic Black-Scholes pricing with regime awareness
- **Behavior Analytics**: 30-day trends, streaks, violation detection

### 🔜 What's Coming (Phase 6.5)
- Live market data integration (Polygon.io, Tradier)
- Real-time watchlist prices and IV percentiles
- Working options scanner
- Paper trading with discipline tracking

---

## Key Technical Details

### Tech Stack
- **Frontend**: Flutter 3.x (cross-platform: iOS, Android, Web, Desktop)
- **State Management**: Riverpod (legacy and modern providers)
- **Navigation**: GoRouter with named routes
- **Backend**: Firebase (Auth, Firestore, Functions)
- **Local Storage**: Hive for caching
- **Charts**: Custom vendored fl_chart

### Project Structure
```
lib/
├── screens/cockpit/          # NEW: Unified dashboard (Phase 6)
├── screens/planner/          # Trade planning workflow
├── screens/journal/          # Journaling UI
├── behavior/                 # Behavior analytics
├── strategy_cockpit/         # Strategy management
├── services/engines/         # Core engines (payoff, risk, pricing, backtest)
├── models/                   # Data models
└── routing/app_router.dart   # GoRouter configuration
```

### Core Engines
1. **Payoff Engine**: Option payoff calculations
2. **Risk Engine**: Max loss, max profit, breakeven
3. **Pricing Engine**: Black-Scholes option pricing
4. **Backtest Engine**: Historical simulation (delegates to riskform_core package)
5. **Regime Classifier**: Market regime detection
6. **Discipline Scorer**: Automated scoring from journal data

---

## Behavioral Design Principles

### 1. Discipline Score (0-100)

Calculated from:
- **Adherence (40pts)**: How closely user followed plan (strike, size, timing)
- **Timing (30pts)**: Entry/exit timing vs plan
- **Risk Management (30pts)**: Position sizing, stop-loss adherence

**Levels**:
- 90-100: Excellent (green)
- 80-89: Good (blue)
- 70-79: Fair (amber)
- <70: Poor (red)

### 2. Journal Blocking (The Secret Sauce)

**Hard constraint**: Users cannot create new trade plans while pending journals exist.

**Flow**:
1. Close position → Adds to `pendingJournals`
2. Try to trade → Blocked with orange "Required Action" card
3. Journal the trade → Removes from pending
4. Can trade again

**Why**: Prevents emotional revenge trading, forces consistency.

### 3. Streak Tracking

- **Clean Streak**: Consecutive trades with score ≥ 80
- **Adherence Streak**: Consecutive trades with adherence ≥ 30
- **Milestones**: 5, 10, 15, 20+ days
- **Visual**: Fire emoji 🔥 at 5+ days

### 4. Watchlist Limit (5 Tickers)

**Why**: Small accounts need focus, not choice paralysis.
**Enforcement**: UI-level validation in cockpit
**Override**: None (hard constraint)

---

## Important Code Locations

### Small Account Cockpit (Phase 6 - NEW)

**Main Screen**: `lib/screens/cockpit/small_account_cockpit_screen.dart`

**Models**:
- `cockpit_state.dart` - Central state aggregation
- `discipline_snapshot.dart` - Discipline scoring logic
- `pending_journal_trade.dart` - Journal blocking system
- `watchlist_item.dart` - Ticker with optional live data
- `weekly_summary.dart` - Weekly performance tracking

**Controller**: `lib/screens/cockpit/controllers/cockpit_controller.dart` (Riverpod StateNotifier)

**Widgets** (7 cards):
- `discipline_header_card.dart` - Always-visible discipline display
- `account_snapshot_card.dart` - Balance + regime
- `required_action_card.dart` - Journal blocking UI
- `watchlist_card.dart` - 5-ticker watchlist
- `open_positions_card.dart` - Position tracker
- `quick_actions_card.dart` - Navigation buttons
- `weekly_summary_card.dart` - Weekly calendar

**Services**:
- `pending_journal_service.dart` - Helper for journal blocking
- `create_test_data.dart` - Test data generator

**Debug**: `lib/screens/cockpit/debug/cockpit_debug_screen.dart` (route: `/debug/cockpit`)

### Journal & Discipline

**Model**: `lib/journal/journal_entry_model.dart`
**Analytics**: `lib/behavior/behavior_analytics.dart`
**Scoring**: Discipline score calculated in cockpit controller from last 5 entries

### Navigation

**Router**: `lib/routing/app_router.dart`
**Key Routes**:
- `/` - Main dashboard
- `/cockpit` - Small Account Cockpit
- `/debug/cockpit` - Cockpit debug screen
- `/planner` - Trade planner
- `/journal` - Journal entry
- `/behavior` - Behavior dashboard

---

## Common Development Tasks

### Adding a New Feature to Cockpit

1. **Add model** in `lib/screens/cockpit/models/`
2. **Update CockpitState** in `cockpit_state.dart`
3. **Fetch data** in `cockpit_controller.dart`
4. **Create widget** in `lib/screens/cockpit/widgets/`
5. **Add to screen** in `small_account_cockpit_screen.dart`

### Creating Test Data

```dart
import 'package:riskform/screens/cockpit/utils/create_test_data.dart';

await CockpitTestData.createAllTestData();
await CockpitTestData.createTestPendingJournal();
await CockpitTestData.clearAllTestData();
```

### Accessing Cockpit State

```dart
final state = ref.watch(cockpitControllerProvider);

if (state.isBlocked) {
  print('User must journal before trading');
}

print('Score: ${state.discipline.currentScore}/100');
await ref.read(cockpitControllerProvider.notifier).refresh();
```

### Adding Pending Journal (when position closes)

```dart
final service = ref.read(pendingJournalServiceProvider);
await service.addPendingJournal(
  positionId: position.id,
  ticker: position.ticker,
  strategy: 'CSP ${position.ticker} \$${position.strike}',
  pnl: position.realizedPnl,
  isPaper: position.isPaper,
);
```

---

## Firebase Collections

### journalEntries
```javascript
{
  uid: string,
  strategyId: string,
  disciplineScore: number (0-100),
  disciplineBreakdown: {
    adherence: number,
    timing: number,
    risk: number
  },
  createdAt: timestamp,
  cycleState: "planned" | "opened" | "closed",
  notes: string,
  tags: string[]
}
```

### users/{uid}/cockpit/watchlist
```javascript
{
  tickers: string[],  // Max 5
  updatedAt: timestamp
}
```

### users/{uid}/cockpit/pendingJournals
```javascript
{
  journals: [{
    positionId: string,
    ticker: string,
    strategy: string,
    pnl: number,
    closedAt: string (ISO),
    isPaper: boolean
  }],
  updatedAt: timestamp
}
```

---

## Testing

### Manual Testing (Debug Screen)

```bash
flutter run
# Navigate to /debug/cockpit
# Click "Create All Test Data"
# Click "Open Cockpit"
```

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

---

## Code Conventions

### File Naming
- Screens: `*_screen.dart`
- Cards/Widgets: `*_card.dart`
- Models: `*_model.dart` or just model name
- Controllers: `*_controller.dart`
- Services: `*_service.dart`

### State Management
- Use Riverpod StateNotifier for complex state
- Use Provider for services
- Use StreamProvider for Firestore real-time
- Use FutureProvider for async data

### Error Handling
- Always wrap Firestore calls in try-catch
- Fail silently for non-critical operations (e.g., caching)
- Show user-friendly errors for critical operations

---

## What NOT to Do

### ❌ Don't Add Complexity
- No more than 5 tickers in watchlist (enforced)
- No adding 47 tabs like Think or Swim
- No enterprise-grade features for small accounts

### ❌ Don't Break Behavioral Friction
- Never allow trading with pending journals (hard block)
- Never make journaling optional
- Never add "skip" or "remind me later" to journal blocking

### ❌ Don't Confuse This with StatusWatch
- This is NOT a service monitoring app
- This is an options trading platform
- Ignore any StatusWatch references in global CLAUDE.md

---

## Documentation

**Core Docs**:
- `README.md` - Project overview
- `COCKPIT_QUICKSTART.md` - 5-minute cockpit setup
- `INTEGRATION_STEPS.md` - Step-by-step integration
- `COCKPIT_INTEGRATED.md` - Integration status

**Design Specs** (`/docs`):
- `COCKPIT_SUMMARY.md` - Vision and philosophy
- `small_account_cockpit_design.md` - Full design specification
- `small_account_cockpit_implementation.md` - Implementation guide

**Phase Docs** (`/docs`):
- Various phase-specific technical documentation

---

## Quick Reference

### Navigate to Cockpit
```dart
context.goNamed('cockpit');
```

### Create Test Data
```dart
await CockpitTestData.createAllTestData();
```

### Check if User is Blocked
```dart
final isBlocked = ref.watch(cockpitControllerProvider).isBlocked;
```

### Refresh Cockpit
```dart
await ref.read(cockpitControllerProvider.notifier).refresh();
```

---

## When Working on RiskForm

1. **Read docs first**: Check README.md, COCKPIT_SUMMARY.md for context
2. **Test with debug screen**: Use `/debug/cockpit` to create test data
3. **Maintain behavioral friction**: Don't break journal blocking
4. **Keep it simple**: Small accounts need simplicity, not features
5. **Discipline first**: Every design decision prioritizes discipline over convenience

---

**Remember**: This is not Think or Swim. This is the Duolingo of options trading.

Complexity kills small accounts. Discipline saves them.
