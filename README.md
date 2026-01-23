# RiskForm

**The discipline-first options trading platform for small accounts**

> "Trading is a behavioral problem, not a P/L problem."

RiskForm is a cross-platform trading platform that helps small account traders ($2K-$25K) build discipline through gamification, behavioral friction, and real-time accountability. Think Duolingo for options trading.

---

## What Makes RiskForm Different

### 🎯 Discipline-First Design

Unlike Think or Swim's complexity overload, RiskForm puts **discipline score** front and center:
- 0-100 score calculated from plan adherence, timing, and risk management
- Always visible, color-coded by performance level
- Tracked over time with sparkline trends

### 🔥 Gamified Consistency

- **Streaks**: Consecutive clean trades (score ≥ 80) with fire emoji at 5+ days
- **Levels**: Excellent/Good/Fair/Poor based on score
- **Milestones**: Celebrations at 5, 10, 15, 20+ day streaks
- **Weekly Calendar**: Visual tracking of clean vs violation days

### 🚫 Behavioral Friction (The Secret Sauce)

**You can't trade without journaling your last trade.**

- Close a position → Automatically moves to "pending journal"
- Try to open new trade → **Hard block** until journaled
- No "skip" or "remind me later"
- Forces good habits through UX constraints

---

## Key Features

### Small Account Cockpit

Unified dashboard with:
- Discipline score and streaks (always visible)
- Account snapshot with regime detection
- Watchlist (max 5 tickers)
- Open positions tracker
- Required actions (journal blocking)
- Weekly performance calendar

**60% fewer taps, 80% less cognitive load** vs traditional platforms.

See [COCKPIT_SUMMARY.md](docs/COCKPIT_SUMMARY.md) for full design philosophy.

---

## Quick Start

```bash
flutter run
# Navigate to /debug/cockpit
# Click "Create All Test Data"
# Click "Open Cockpit"
```

See [COCKPIT_QUICKSTART.md](COCKPIT_QUICKSTART.md) for detailed setup.

---

## Project Structure

```
lib/screens/cockpit/     # Unified dashboard (NEW!)
lib/screens/planner/     # Trade planning
lib/screens/journal/     # Journaling
lib/behavior/            # Behavior analytics
lib/strategy_cockpit/    # Strategy management
```

Full documentation in `/docs`

---

## Philosophy

**Most traders fail not because of bad strategies, but bad behavior.**

Traditional platforms give you more data. **RiskForm gives you discipline.**

- **Duolingo Model**: Gamified practice, addictive streaks, forced lessons
- **Small Account Focus**: 5 tickers max, simplicity over complexity
- **Behavioral Friction**: Journal blocking prevents emotional trading

---

## Competitive Advantage

| Feature | Think or Swim | RiskForm |
|---------|--------------|----------|
| Discipline Scoring | ❌ | ✅ |
| Journal Blocking | ❌ | ✅ |
| Streak Tracking | ❌ | ✅ |
| Small Account Focus | ❌ | ✅ |
| Cross-Platform | Desktop only | All platforms |

**TOS** shows you 10,000 data points. **RiskForm** makes you disciplined.

---

Built with ❤️ for small account traders who want discipline over complexity.
