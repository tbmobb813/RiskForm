# 📘 **3. Wheel Lifecycle Specification (Markdown)**

```markdown
# Wheel Lifecycle Specification

The Wheel strategy is modeled as a deterministic state machine with two major phases:
1. Cash-Secured Put (CSP)
2. Covered Call (CC)

---

# Lifecycle States

## 1. CSP Open
- Premium collected
- Capital reserved
- DTE countdown begins

## 2. CSP Expiration
### If price > strike:
- CSP expires OTM
- No assignment
- Cycle continues

### If price ≤ strike:
- Assignment occurs
- Shares acquired
- Move to CC phase

---

## 3. CC Open
- Shares covered
- Premium collected
- DTE countdown begins

---

## 4. CC Expiration
### If price < strike:
- CC expires OTM
- Shares retained
- Cycle ends

### If price ≥ strike:
- Called away
- Shares sold
- Cycle ends

---

# CycleOutcome Enum
- `expiredOTM`
- `assigned`
- `calledAway`

---

# Cycle Completion
A cycle begins when a CSP is opened and ends when the CC expires or is assigned.
