import * as admin from 'firebase-admin';

// Usage:
//   node -r ts-node/register functions/scripts/backfill_owner_uid.ts [--apply] [--limit N]
// Default is dry-run. Use --apply to perform writes. Use --limit to cap processed docs.

async function main() {
  const argv = process.argv.slice(2);
  const apply = argv.includes('--apply');
  const limitArgIndex = argv.findIndex(a => a === '--limit');
  const limit = limitArgIndex >= 0 && argv[limitArgIndex + 1] ? parseInt(argv[limitArgIndex + 1], 10) : Infinity;

  console.log(`Backfill ownerUid: starting (apply=${apply}, limit=${isFinite(limit) ? limit : '∞'})`);

  // Initialize admin with default credentials (ADC or service account key via env)
  admin.initializeApp();
  const db = admin.firestore();

  const positionsColl = db.collection('positions');

  let processed = 0;
  let updated = 0;
  let skipped = 0;
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
  const pageSize = 500;

  while (processed < limit) {
    let q = positionsColl.orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (lastDoc) q = q.startAfter(lastDoc.id);

    const snap = await q.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      if (processed >= limit) break;
      processed++;

      const data = doc.data();
      const ownerUid = data.ownerUid as string | undefined;
      // Skip if ownerUid already present and non-empty
      if (ownerUid) {
        skipped++;
        continue;
      }

      // If no planId, nothing to backfill
      const planId = data.planId as string | undefined;
      if (!planId) {
        skipped++;
        continue;
      }

      // Read journal entry for planId
      try {
        const j = await db.collection('journalEntries').doc(planId).get();
        if (!j.exists) {
          skipped++;
          continue;
        }
        const juid = j.get('uid') as string | undefined;
        if (!juid) {
          skipped++;
          continue;
        }

        console.log(`doc=${doc.id}: will set ownerUid=${juid}`);
        if (apply) {
          await doc.ref.set({ ownerUid: juid }, { merge: true });
          updated++;
        }
      } catch (e) {
        console.error(`doc=${doc.id}: error reading journal ${planId}:`, e);
      }
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < pageSize) break;
  }

  console.log(`Done. processed=${processed}, updated=${updated}, skipped=${skipped}`);
}

main().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
