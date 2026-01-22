/// <reference types="mocha" />

import * as assert from 'assert';
import * as admin from 'firebase-admin';
import * as fft from 'firebase-functions-test';

// Ensure emulator host
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';

const test = fft.default();

import { onPositionCreated } from '../src/positionEnforcer';

describe('positionEnforcer integration', () => {
  before(async () => {
    if (!admin.apps.length) {
      admin.initializeApp({ projectId: 'demo-project' });
    }
  });

  after(() => {
    test.cleanup();
  });

  it('rejects position that exceeds max allocation for small account', async () => {
    const db = admin.firestore();

    // Create a journal entry owned by test-user
    const journalRef = db.collection('journalEntries').doc('j-pos-test');
    await journalRef.set({ uid: 'test-user', createdAt: admin.firestore.FieldValue.serverTimestamp() });

    // Create small account settings for user: startingCapital 1000, maxAllocationPct 0.1 (max 100)
    const settingsRef = db.doc('users/test-user/smallAccountSettings/settings');
    await settingsRef.set({ enabled: true, startingCapital: 1000, maxAllocationPct: 0.1, minTradeSize: 10, maxOpenPositions: 2 });

    // Build a position that exceeds allocation: entryPrice 200, contracts 1 => cost 200 > 100
    const posData = { planId: 'j-pos-test', entryPrice: 200, contracts: 1, strategyId: 'wheel', cycleState: 'opened' };

    const snap = test.firestore.makeDocumentSnapshot(posData, 'positions/pos1');
    const wrapped = test.wrap(onPositionCreated) as any;

    await wrapped(snap, { params: { posId: 'pos1' } });

    // Read position doc and violations
    const posDoc = await db.doc('positions/pos1').get();
    const p = posDoc.data();
    assert.ok(p);
    assert.strictEqual(p?.rejected, true);
    assert.strictEqual(p?.rejectionReason, 'exceeds_max_allocation');

    const violations = await db.collection('violations').where('posId', '==', 'pos1').get();
    assert.strictEqual(violations.size > 0, true);
    const v = violations.docs[0].data();
    assert.strictEqual(v.reason, 'exceeds_max_allocation');
  });
});
