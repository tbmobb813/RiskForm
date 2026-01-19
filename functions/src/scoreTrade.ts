import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Callable function to compute and persist discipline score for a journal entry.
export const scoreTrade = functions.https.onCall(async (data, context) => {
  // Authentication
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const journalId = data?.journalId as string | undefined;
  const plannedParams = data?.plannedParams as any | undefined;
  const executedParams = data?.executedParams as any | undefined;

  if (!journalId || !plannedParams || !executedParams) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  const journalRef = db.collection('journalEntries').doc(journalId);
  const snap = await journalRef.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError('not-found', 'Journal entry not found');
  }

  const ownerUid = snap.get('uid') as string | undefined;
  if (ownerUid && ownerUid !== uid) {
    throw new functions.https.HttpsError('permission-denied', 'Not owner of this journal entry');
  }

  // Compute score (simple port of local engine heuristics)
  let adherence = 40;
  try {
      if (plannedParams?.strike != null && executedParams?.strike != null && plannedParams.strike !== executedParams.strike) adherence -= 15;
      // Parse expiration values defensively: accept ISO strings, millis, or Firestore-like {seconds,nanoseconds}
      const parseToDate = (v: any): Date | null => {
        if (v == null) return null;
        if (v instanceof Date) return v;
        if (typeof v === 'string' || typeof v === 'number') {
          const d = new Date(v);
          if (!isNaN(d.getTime())) return d;
        }
        // Firestore serialized timestamp shapes
        const secs = v?.seconds ?? v?._seconds;
        const nanos = v?.nanoseconds ?? v?._nanoseconds ?? 0;
        if (secs != null) {
          const s = typeof secs === 'number' ? secs : Number(secs);
          const n = typeof nanos === 'number' ? nanos : Number(nanos || 0);
          return new Date(s * 1000 + Math.floor(n / 1e6));
        }
        return null;
      };

      const plannedExpDate = parseToDate(plannedParams?.expiration);
      const execExpDate = parseToDate(executedParams?.expiration);
      if (plannedExpDate != null && execExpDate != null) {
        if (plannedExpDate.getTime() !== execExpDate.getTime()) adherence -= 10;
      } else if (plannedParams?.expiration != null && executedParams?.expiration != null && plannedParams.expiration !== executedParams.expiration) {
        adherence -= 10;
      }

      if (plannedParams?.contracts != null && executedParams?.contracts != null && plannedParams.contracts !== executedParams.contracts) adherence -= 15;
  } catch (e) {
    // ignore
  }

  let timing = 30;
  try {
    const parseToDateLocal = (v: any): Date | null => {
      if (v == null) return null;
      if (v instanceof Date) return v;
      if (typeof v === 'string' || typeof v === 'number') {
        const d = new Date(v);
        if (!isNaN(d.getTime())) return d;
      }
      const secs = v?.seconds ?? v?._seconds;
      const nanos = v?.nanoseconds ?? v?._nanoseconds ?? 0;
      if (secs != null) {
        const s = typeof secs === 'number' ? secs : Number(secs);
        const n = typeof nanos === 'number' ? nanos : Number(nanos || 0);
        return new Date(s * 1000 + Math.floor(n / 1e6));
      }
      return null;
    };

    const plannedTime = plannedParams?.plannedEntryTime ? parseToDateLocal(plannedParams.plannedEntryTime) : null;
    const executedTime = executedParams?.executedAt ? parseToDateLocal(executedParams.executedAt) : null;
    if (plannedTime && executedTime) {
      const diff = Math.abs((executedTime.getTime() - plannedTime.getTime()) / 60000);
      if (diff > 30) timing -= 10;
      if (diff > 60) timing -= 20;
    }
  } catch (e) {}

  let risk = 30;
  try {
    const stopLoss = plannedParams?.stopLoss;
    const accountSize = (plannedParams?.accountSize as number) ?? 10000;
    const contractSize = (plannedParams?.contractSize as number) ?? 100;
    const execEntry = executedParams?.entryPrice as number | undefined;
    const contracts = (executedParams?.contracts as number) ?? (plannedParams?.contracts as number) ?? 0;
    let positionShares = 0;
    if (plannedParams?.positionSize != null) positionShares = plannedParams.positionSize as number;
    else if (contracts > 0) positionShares = contracts * contractSize;

    let dollarRisk = 0;
    if (stopLoss != null && execEntry != null && positionShares > 0) {
      dollarRisk = Math.abs(execEntry - stopLoss) * positionShares;
    }

    const planMaxRiskDollar = plannedParams?.maxRiskDollar as number | undefined;
    const planMaxRiskPct = plannedParams?.maxRiskPercent as number | undefined;
    if (planMaxRiskDollar != null && dollarRisk > planMaxRiskDollar) risk -= 15;
    if (planMaxRiskPct != null && accountSize > 0) {
      const riskPct = (dollarRisk / accountSize) * 100.0;
      if (riskPct > planMaxRiskPct) risk -= 15;
    }
  } catch (e) {}

  adherence = Math.max(0, Math.min(40, adherence));
  timing = Math.max(0, Math.min(30, timing));
  risk = Math.max(0, Math.min(30, risk));
  const total = adherence + timing + risk;

  const breakdown = {
    adherence,
    timing,
    risk,
  };

  // Persist the score to the journal entry with audit fields
  await journalRef.update({
    disciplineScore: total,
    disciplineBreakdown: breakdown,
    scoredBy: uid,
    scoredAt: admin.firestore.FieldValue.serverTimestamp(),
    scoredSource: 'cloud-function',
  });

  return { total, breakdown, scoredBy: uid };
});
