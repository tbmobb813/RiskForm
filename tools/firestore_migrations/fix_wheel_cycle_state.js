// Migration: fix_wheel_cycle_state.js
// Scans users/*/wheel/cycle documents and repairs invalid `state` values.
import admin from 'firebase-admin';
import fs from 'fs';

const TELEMETRY_URL = process.env.TELEMETRY_URL || null;
const DRY_RUN = (process.env.DRY_RUN || 'false').toLowerCase() === 'true';

function nowIso() { return new Date().toISOString(); }

async function sendTelemetry(payload) {
  if (!TELEMETRY_URL) return;
  try {
    // Node 18+ has global fetch.
    await fetch(TELEMETRY_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
  } catch (err) {
    console.error('Telemetry send failed', err?.message || err);
  }
}

function safeInt(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === 'number') return Math.trunc(v);
  if (typeof v === 'string') {
    const p = parseInt(v, 10);
    return Number.isNaN(p) ? null : p;
  }
  return null;
}

function isWheelStateIndexValid(i) {
  return Number.isInteger(i) && i >= 0 && i <= 5; // 6 enum values
}

async function main() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('GOOGLE_APPLICATION_CREDENTIALS must point to a service account JSON.');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  const db = admin.firestore();

  console.log(`[${nowIso()}] Scanning users for wheel/cycle documents...`);

  const usersSnap = await db.collection('users').listDocuments();
  let fixed = 0;
  let total = 0;

  for (const userDocRef of usersSnap) {
    const uid = userDocRef.id;
    const cycleDocRef = userDocRef.collection('wheel').doc('cycle');
    const doc = await cycleDocRef.get();
    if (!doc.exists) continue;
    total += 1;
    const data = doc.data() || {};
    const rawState = data.state;
    const idx = safeInt(rawState);
    if (!isWheelStateIndexValid(idx)) {
      console.warn(`[${nowIso()}] user=${uid} invalid state=${rawState} -> would reset to idle`);
      // Prepare updated payload but preserve cycleCount/lastTransition if possible
      const updated = {
        state: 0, // idle
        cycleCount: (typeof data.cycleCount === 'number') ? data.cycleCount : (data.cycleCount ? Number(data.cycleCount) : 0),
        lastTransition: data.lastTransition || null,
      };

      if (DRY_RUN) {
        console.log(`[${nowIso()}] DRY_RUN: would update user=${uid} with`, updated);
      } else {
        await cycleDocRef.set(updated, { merge: true });
        fixed += 1;
      }

      await sendTelemetry({
        event: 'wheel_cycle_state_fix',
        timestamp: nowIso(),
        uid,
        rawState,
        updatedState: 0,
        dryRun: DRY_RUN,
      });
    }
  }

  console.log(`[${nowIso()}] Done. scanned=${total} fixed=${fixed}`);
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(2);
});
