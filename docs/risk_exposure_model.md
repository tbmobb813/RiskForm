
---

# 📘 **5. Risk Exposure Model (Markdown)**

```markdown
# Risk Exposure Model

The Dashboard displays risk exposure derived from:
- open CSP risk
- open CC risk
- assignment probability
- capital at risk
- regime context

---

# Components of Risk Exposure

## 1. CSP Risk
- Max loss = strike * 100 – premium
- Probability of assignment (based on delta or historical hit rate)
- Capital reserved = strike * 100

## 2. CC Risk
- Opportunity cost (capped upside)
- Probability of being called away
- Premium decay profile

## 3. Assignment Risk
- Derived from:
  - cycle history
  - regime classification
  - strike distance
  - volatility

## 4. Regime Risk
- Downtrend cycles penalized
- Uptrend cycles rewarded
- Sideways cycles neutral

---

# Dashboard Risk Summary
Displayed as:
- Capital at risk
- Assignment likelihood
- Regime context
- Cycle state
- Next logical action
