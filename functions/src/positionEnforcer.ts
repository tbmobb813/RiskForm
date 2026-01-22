import {onDocumentCreated} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Firestore trigger to enforce small-account rules when a position is created.
export const onPositionCreated = onDocumentCreated('positions/{posId}', async (eventOrSnap: any, maybeContext?: any) => {
  // Support both v2 event shape (event.data, event.params) and the
  // firebase-functions-test wrapped invocation which may call (snap, context).
  let snap: any;
  let params: any = undefined;

  if (maybeContext) {
    // Called as (snap, context)
    snap = eventOrSnap;
    params = maybeContext.params;
  } else if (eventOrSnap && eventOrSnap.data !== undefined) {
    // v2 event shape
    snap = eventOrSnap.data;
    params = eventOrSnap.params;
  } else {
    snap = eventOrSnap;
  }

  const data = typeof snap?.data === 'function' ? snap.data() : snap?.data;
  const posRef = snap?.ref || (params && params.posId ? db.doc(`positions/${params.posId}`) : undefined);

  const planId = data?.planId as string | undefined;
  const entryPrice = Number(data?.entryPrice);
  const contracts = Number(data?.contracts) || 0;

  if (!planId || !entryPrice || contracts <= 0) {
    // Not enough information to enforce; set owner from plan if possible and exit
    try {
      if (planId) {
        const j = await db.collection('journalEntries').doc(planId).get();
        if (j.exists) {
          const ownerUid = j.get('uid') as string | undefined;
            if (ownerUid && posRef) {
            await posRef.set({ ownerUid }, { merge: true });
          }
        }
      }
    } catch (e) {}
    return;
  }

  // Lookup journal entry to find owner uid
  const journalRef = db.collection('journalEntries').doc(planId);
  const journalSnap = await journalRef.get();
  const ownerUid = journalSnap.exists ? (journalSnap.get('uid') as string | undefined) : undefined;

  // Attach ownerUid for auditing
    if (ownerUid && posRef) {
    await posRef.set({ ownerUid }, { merge: true }).catch(() => {});
  }

  // Read user's small account settings from Firestore
  let sa: any = null;
  if (ownerUid) {
    try {
      const settingsDoc = await db.doc(`users/${ownerUid}/smallAccountSettings/settings`).get();
      if (settingsDoc.exists) sa = settingsDoc.data();
    } catch (e) {
      sa = null;
    }
  }

  if (!sa || sa.enabled !== true) {
    return; // nothing to enforce
  }

  const entryCost = entryPrice * contracts;

  // Enforcement: min trade size
    if (sa.minTradeSize != null && entryCost < Number(sa.minTradeSize)) {
    await posRef.set({ rejected: true, rejectionReason: 'below_min_trade_size', rejectedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    await db.collection('violations').add({ type: 'small_account', uid: ownerUid, posId: posRef.id, reason: 'below_min_trade_size', createdAt: admin.firestore.FieldValue.serverTimestamp() });
    return;
  }

  // Enforcement: max allocation
  if (sa.startingCapital != null && sa.maxAllocationPct != null) {
    const maxAlloc = Number(sa.startingCapital) * Number(sa.maxAllocationPct);
      if (entryCost > maxAlloc) {
      await posRef.set({ rejected: true, rejectionReason: 'exceeds_max_allocation', rejectedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      await db.collection('violations').add({ type: 'small_account', uid: ownerUid, posId: posRef.id, reason: 'exceeds_max_allocation', createdAt: admin.firestore.FieldValue.serverTimestamp() });
      return;
    }
  }

  // Enforcement: max open positions — count positions that belong to this owner and are opened
  if (sa.maxOpenPositions != null && ownerUid) {
    try {
      const openPositions = await db.collection('positions').where('cycleState', '==', 'opened').get();
      let count = 0;
      for (const doc of openPositions.docs) {
        const p = doc.data();
        const pid = p.planId as string | undefined;
        if (!pid) continue;
        const j = await db.collection('journalEntries').doc(pid).get();
        if (!j.exists) continue;
        const juid = j.get('uid') as string | undefined;
        if (juid === ownerUid) count++;
        if (count >= Number(sa.maxOpenPositions)) break;
      }
        if (count >= Number(sa.maxOpenPositions)) {
        await posRef.set({ rejected: true, rejectionReason: 'max_open_positions_reached', rejectedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
        await db.collection('violations').add({ type: 'small_account', uid: ownerUid, posId: posRef.id, reason: 'max_open_positions_reached', createdAt: admin.firestore.FieldValue.serverTimestamp() });
        return;
      }
    } catch (e) {
      // If counting fails, don't block; just continue
    }
  }

  // If we reached here, position passed enforcement — set acceptedAt for audit
  if (posRef) {
    await posRef.set({ acceptedAt: admin.firestore.FieldValue.serverTimestamp(), enforcedBy: 'positionEnforcer' }, { merge: true }).catch(() => {});
  }
  return;
});
