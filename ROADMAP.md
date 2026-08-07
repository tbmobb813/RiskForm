# RiskForm — Phased Roadmap

This is the canonical source of truth for RiskForm's business/product phasing. If another doc in `/docs` states a conflicting phase status, this file wins — the others are historical design context.

## Positioning shift (applies to every phase)

Stop selling "Wheel tracker + discipline app." Sell **"options scenario simulator — stress-test your strategy before you risk capital."** Target ONE's paying audience, not the free-tracker crowd.

---

## Phase 0 — Re-scope (Weeks 1–4)

**Status: done (this pass).**

- README/positioning rewritten around simulation + regime stress-testing, not tracking. See `README.md`.
- Free/paid split decided (below); implementation deferred to Phase 2.
- Platform consolidation decision recorded (below); no code removed.
- Frozen/cut inventory recorded (below).

### Frozen / cut inventory

Unlike a from-scratch roadmap, RiskForm already has real code and infrastructure behind two of the three items originally slated to be "cut." This section reflects what's actually true today, not what a green-field plan would assume:

- **Cloud distributed backtesting — already built and deployed.** `cloud_worker/` is a real Dart service running on Google Cloud Run, with its own CI/CD (`cloud-worker-deploy.yml`, `cloud-worker-ci.yml`). This is **frozen, not torn down**: no new features, no roadmap dependency on it, until Phase 2's gate clears. The deployment keeps running as-is.
- **Live broker execution sync — not built.** Only CSV import from broker exports exists (`lib/state/import_notifier.dart`, `lib/services/import/csv_parsers.dart`, supporting tastytrade/thinkorswim/Robinhood/Fidelity exports). Stays off the roadmap indefinitely, per the original plan.
- **Multi-strategy orchestration — not built.** Only docs-level design notes exist; no multi-strategy trading orchestration code. Stays off the roadmap indefinitely, per the original plan.

### Platform consolidation

Consolidate focus to web-first. Android, iOS, macOS, Linux, and Windows are real Flutter build targets already in this repo (`android/`, `ios/`, `macos/`, `linux/`, `windows/`), but only web is exercised in CI (`firebase-hosting-*.yml`) today. Decision: **document-only** — those five platform directories stay in the repo untouched, but get no active CI runs or development time until a much later phase (see Phase 5) revisits them. This avoids a six-platform solo-dev trap without a destructive, hard-to-reverse deletion.

### Free/paid split decision

- **Free**: simulator core — Wheel lifecycle simulation, pricing/assignment engines, basic regime segmentation, journal.
- **Pro (future, not yet implemented)**: deeper regime-scenario depth, strategy comparison across configs, sim-driven discipline scoring as a premium analytics layer.
- **Price anchor**: ~$15–25/mo or ~$150–200/yr, anchored against ONE's ~$500/yr (not against free trackers' $0–15/mo).
- **Existing gating hook**: `isProUserProvider` in `lib/screens/dashboard/tools_and_strategy_library.dart:9` is currently a hardcoded-`false` stub gating one tool ("Hedge Comparison"). Phase 2 is where this gets wired to real billing and extended to gate the features above — not built yet.

### Risk / follow-up flag (not resolved in Phase 0)

RiskForm's Phase 6 work already shipped a **live recommendations engine** and a **strategy narrative engine** (`docs/phase_6_4_live_recommendations_engine.md`, `docs/specs/phase_5_9_strategy_narrative_engine.md`). Phase 4 below sets a hard constraint that AI-generated output must stay strictly post-hoc/narrative and never directive ("you should roll this"), to avoid unregistered-investment-adviser exposure under Reg BI / the Advisers Act. Before or alongside Phase 4 work, audit the existing recommendations/narrative engine's actual output copy against that constraint — it predates this roadmap and hasn't been reviewed against it.

---

## Phase 1 — Wheel-only regime simulator MVP (Months 1–4)

- Repackage what's already built (pricing/assignment/lifecycle engines, regime classifier — further along than a from-scratch plan would assume, see `docs/SYSTEM_OVERVIEW.md`) into the new frame: "run this CSP/CC campaign through Uptrend/Downtrend/Sideways regimes and see the outcome."
- New feature, not cosmetic: let a user pick a historical regime window and replay a hypothetical Wheel campaign through it — this is the wedge no Wheel tracker offers.
- Ship free, web, no-login-friction version. Launch on r/thetagang with the simulator framing, not the tracker framing.
- **Gate:** 500 signups / 25+ weekly-engaged users within 90 days. Miss this badly → the demand assumption is wrong, stop before Phase 2.

## Phase 2 — Validate willingness-to-pay (Months 4–9)

- Talk to the most engaged free users directly. Ask what they'd pay for — anchor against ONE's ~$500/yr, not against free trackers' $0–15/mo.
- Launch a single Pro tier (~$15–25/mo or ~$150–200/yr) gating: deeper regime scenarios, strategy comparison across configs, sim-driven discipline scoring (adherence-to-plan derived automatically from simulated vs. actual behavior — the real differentiator vs. Edgewonk's manual mood logs).
- **Gate:** ~$1k MRR or ~100 paying users within 12 months of monetizing, with >40% month-2 retention. Miss this → fold back to Stage 4 of the original plan (open-source it, stop investing).

## Phase 3 — Second strategy type (Months 9–15, conditional)

- Only start this if Phase 2's gate clears. Add exactly one new strategy (verticals or PMCC — whichever paying users actually ask for, not the one that sounds impressive).
- Do not build the full multi-strategy suite speculatively. One validated addition at a time.

## Phase 4 — AI explainer layer (parallel to Phase 3, once there's simulation volume)

- Strictly post-hoc narration of simulation output: "this condor's max loss triggered because IV expanded faster than theta decayed."
- **Hard constraint, non-negotiable:** never "you should roll this" or any directive language. That line is what keeps this a software tool instead of an unregistered investment adviser under Reg BI / the Advisers Act. Design this in from day one, not as a retrofit.
- See the Phase 0 risk/follow-up flag above — the existing recommendations/narrative engine needs an audit against this constraint as part of this phase's work.

## Phase 5 — Long-horizon, conditional (15+ months out)

- Mobile builds (revisiting the platforms frozen in Phase 0), deeper historical options data licensing, read-only broker position import (still no execution, still no personalized recommendations).
- Only pursue if MRR trajectory from Phase 2–3 actually justifies the cost — historical options data licensing is genuinely expensive, which is part of why ONE prices where it does.

---

## Kill switch

Any missed gate above (Phase 1's 90-day signup bar, Phase 2's 12-month revenue bar) is a stop-and-reassess point, not a reason to push forward on conviction alone.
