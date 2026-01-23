import {onDocumentWritten} from 'firebase-functions/v2/firestore';
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const recomputeStrategyHealth = onDocumentWritten("strategyHealth/{strategyId}", async (event) => {
    const strategyId = event.params.strategyId;

    const after = event.data?.after?.data();
    if (!after) return;

    // Only recompute if marked dirty
    if (!after.dirty) return;

    console.log(`Recomputing health for strategy ${strategyId}...`);

    // ------------------------------------------------------------
    // 1. Load all cycles for this strategy
    // ------------------------------------------------------------
    const cyclesSnap = await db
      .collection("strategyCycles")
      .where("strategyId", "==", strategyId)
      .orderBy("startedAt")
      .get();

    const cycles = cyclesSnap.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));

    // ------------------------------------------------------------
    // 2. Compute aggregated health snapshot
    // ------------------------------------------------------------
    const snapshot = computeHealthSnapshot(strategyId, cycles);

    // ------------------------------------------------------------
    // 3. Write snapshot back to Firestore
    // ------------------------------------------------------------
    await db.collection("strategyHealth").doc(strategyId).set({
      ...snapshot,
      dirty: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Health recompute complete for ${strategyId}`);
  });


// ===================================================================
// PURE HEALTH AGGREGATION ENGINE (mirrors the Dart implementation)
// ===================================================================
function computeHealthSnapshot(strategyId: string, cycles: any[]) {
  if (cycles.length === 0) {
    return {
      strategyId,
      pnlTrend: [],
      disciplineTrend: [],
      regimePerformance: {},
      cycleSummaries: [],
      regimeWeaknesses: [],
      currentRegime: null,
      currentRegimeHint: null,
    };
  }

  // ------------------------------------------------------------
  // 1. PnL Trend
  // ------------------------------------------------------------
  const pnlTrend = cycles.map(
    (c) => (Number(c.realizedPnl) || 0) + (Number(c.unrealizedPnl) || 0)
  );

  // ------------------------------------------------------------
  // 2. Discipline Trend
  // ------------------------------------------------------------
  const disciplineTrend = cycles.map((c) => Number(c.disciplineScore) || 0);

  // ------------------------------------------------------------
  // 3. Regime Performance Aggregation
  // ------------------------------------------------------------
  const regimeStats: Record<string, any> = {};

  for (const c of cycles) {
    const regime = c.dominantRegime || "unknown";
    if (!regimeStats[regime]) {
      regimeStats[regime] = {
        count: 0,
        wins: 0,
        totalPnl: 0,
        totalDiscipline: 0,
      };
    }

    const stats = regimeStats[regime];
    stats.count++;
    stats.totalPnl += Number(c.realizedPnl) || 0;
    stats.totalDiscipline += Number(c.disciplineScore) || 0;
    if ((Number(c.realizedPnl) || 0) > 0) stats.wins++;
  }

  const regimePerformance: Record<string, any> = {};
  for (const regime of Object.keys(regimeStats)) {
    const s = regimeStats[regime];
    regimePerformance[regime] = {
      pnl: s.totalPnl,
      winRate: s.count === 0 ? 0 : s.wins / s.count,
      avgDiscipline: s.count === 0 ? 0 : s.totalDiscipline / s.count,
    };
  }

  // ------------------------------------------------------------
  // 4. Weakness Flags
  // ------------------------------------------------------------
  const weaknesses: string[] = [];

  if (disciplineTrend.length > 0 && disciplineTrend[disciplineTrend.length - 1] < 60) {
    weaknesses.push("discipline_slipping");
  }

  if (pnlTrend.length >= 3) {
    const last3 = pnlTrend.slice(-3);
    if (last3.every((p) => p < 0)) {
      weaknesses.push("recent_losses");
    }
  }

  // ------------------------------------------------------------
  // 5. Cycle Summaries
  // ------------------------------------------------------------
  const cycleSummaries = cycles.map((c) => ({
    cycleId: c.id,
    pnl: (Number(c.realizedPnl) || 0) + (Number(c.unrealizedPnl) || 0),
    disciplineScore: Number(c.disciplineScore) || 0,
    regime: c.dominantRegime || null,
    startedAt: c.startedAt,
    closedAt: c.closedAt || null,
  }));

  // ------------------------------------------------------------
  // 6. Current Regime Hint
  // ------------------------------------------------------------
  const lastCycle = cycles[cycles.length - 1];
  const currentRegime = lastCycle.dominantRegime || null;

  const currentRegimeHint =
    currentRegime === "uptrend"
      ? "Strategy performs best selling premium in strength."
      : currentRegime === "downtrend"
      ? "Strategy may require defensive adjustments."
      : currentRegime === "sideways"
      ? "Neutral conditions favor income strategies."
      : "No regime signal available.";

  // ------------------------------------------------------------
  // 7. Final snapshot
  // ------------------------------------------------------------
  return {
    strategyId,
    pnlTrend,
    disciplineTrend,
    regimePerformance,
    cycleSummaries,
    regimeWeaknesses: weaknesses,
    currentRegime,
    currentRegimeHint,
  };
}
