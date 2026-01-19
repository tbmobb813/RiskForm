# Discipline Model

The Discipline Engine quantifies user behavior over time using journal entries.

---

# DisciplineScore
A composite score (0–100) based on four pillars:

## 1. Plan Adherence (35%)
Completed cycles / total cycles.

## 2. Cycle Quality (25%)
Maps average cycle return into 0–1 range.

## 3. Assignment Behavior (20%)
Called-away events / assignments.

## 4. Regime Awareness (20%)
Penalizes poor performance in downtrends.

---

# Daily Discipline Snapshot
- `date`
- `score`
- `cyclesCompleted`
- `assignments`
- `calledAway`

---

# Streaks
- `disciplineStreakDays`
- `cleanCycleStreak`
- `noAssignmentStreak`

---

# Habits
- `cleanCycleRate`
- `assignmentAvoidanceRate`
- `planAdherenceRate`

---

# Behavioral Philosophy
The system reinforces:
- consistency  
- adherence  
- clean execution  
- regime awareness  
- long-term discipline  
