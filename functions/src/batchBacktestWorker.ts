import {onDocumentWritten} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * Triggered whenever a backtest run is written.
 * If all runs in the batch are complete, finalize the batch summary.
 */
export const finalizeBatchBacktest = onDocumentWritten('strategyBacktests/{strategyId}/runs/{runId}', async (event) => {
    const strategyId = event.params.strategyId as string;
    const after = event.data?.after?.data();

    if (!after) return;

    const batchId = after.batchId as string | undefined;
    if (!batchId) return;

    // Only react when a run becomes complete
    if (after.status !== 'complete') return;

    const batchRef = db
      .collection('strategyBacktests')
      .doc(strategyId)
      .collection('batches')
      .doc(batchId);

    const batchSnap = await batchRef.get();
    if (!batchSnap.exists) return;

    const batchData = batchSnap.data()!;
    const runIds: string[] = batchData.runIds || [];

    if (runIds.length === 0) return;

    // Load all runs in this batch
    const runDocs = await Promise.all(
      runIds.map((id) =>
        db
          .collection('strategyBacktests')
          .doc(strategyId)
          .collection('runs')
          .doc(id)
          .get()
      )
    );

    const runs = runDocs
      .filter((d) => d.exists)
      .map((d) => ({ runId: d.id, ...(d.data() as Record<string, any>) }));

    // If any run is not complete yet, do nothing
    if (runs.some((r) => (r as any).status !== 'complete')) {
      return;
    }

    // All runs complete → compute summary
    const summary = computeBatchSummary(runs);

    await batchRef.update({
      status: 'complete',
      summary,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `Batch ${batchId} for strategy ${strategyId} finalized with ${runs.length} runs.`
    );
  });

/**
 * Compute batch summary: best/worst config, regime weaknesses, summary note.
 */
function computeBatchSummary(runs: any[]) {
  const best = findBest(runs);
  const worst = findWorst(runs);
  const regimeWeaknesses = computeRegimeWeaknesses(runs);
  const summaryNote = buildSummaryNote(best, worst, regimeWeaknesses);

  return {
    bestConfig: best ? best.parameters : null,
    worstConfig: worst ? worst.parameters : null,
    regimeWeaknesses,
    summaryNote,
  };
}

function findBest(runs: any[]): any | null {
  let best: any | null = null;
  let bestScore = -Infinity;

  for (const r of runs) {
    const m = (r.metrics || {}) as any;
    const pnl = Number(m.pnl || 0);
    const dd = Number(m.maxDrawdown || 0);
    const winRate = Number(m.winRate || 0);

    // Simple composite score
    const score = pnl - dd + winRate * 100;
    if (score > bestScore) {
      bestScore = score;
      best = r;
    }
  }
  return best;
}

function findWorst(runs: any[]): any | null {
  let worst: any | null = null;
  let worstScore = Infinity;

  for (const r of runs) {
    const m = (r.metrics || {}) as any;
    const pnl = Number(m.pnl || 0);
    const dd = Number(m.maxDrawdown || 0);
    const winRate = Number(m.winRate || 0);

    const score = pnl - dd + winRate * 100;
    if (score < worstScore) {
      worstScore = score;
      worst = r;
    }
  }
  return worst;
}

function computeRegimeWeaknesses(runs: any[]): Record<string, string> {
  const regimePnl: Record<string, number> = {};
  const regimeCount: Record<string, number> = {};

  for (const r of runs) {
    const rb = (r.regimeBreakdown || {}) as any;
    Object.keys(rb).forEach((regime) => {
      const v = rb[regime] || {};
      const pnl = Number(v.pnl || 0);
      regimePnl[regime] = (regimePnl[regime] || 0) + pnl;
      regimeCount[regime] = (regimeCount[regime] || 0) + 1;
    });
  }

  const notes: Record<string, string> = {};
  Object.keys(regimePnl).forEach((regime) => {
    const avg = regimePnl[regime] / (regimeCount[regime] || 1);
    if (avg < 0) {
      notes[regime] = `Strategy tends to lose in ${regime} conditions.`;
    } else if (avg > 0) {
      notes[regime] = `Strategy tends to perform well in ${regime} conditions.`;
    }
  });

  return notes;
}

function buildSummaryNote(
  best: any | null,
  worst: any | null,
  regimeWeaknesses: Record<string, string>
): string {
  if (!best) return 'No comparison available.';

  const bestParams = best.parameters || {};
  const buf: string[] = [];

  buf.push(`Best configuration found: ${JSON.stringify(bestParams)}.`);

  if (worst) {
    const worstParams = worst.parameters || {};
    buf.push(`Weak configuration: ${JSON.stringify(worstParams)}.`);
  }

  const regimes = Object.values(regimeWeaknesses);
  if (regimes.length > 0) {
    buf.push('Regime notes:');
    regimes.forEach((note) => buf.push(`- ${note}`));
  }

  return buf.join(' ');
}
