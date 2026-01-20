/// <reference types="mocha" />

import * as assert from 'assert';
import * as admin from 'firebase-admin';
import * as fft from 'firebase-functions-test';

// Set emulator host before requiring admin/functions
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';

const test = fft.default();

// Import the function handler (ts-node/register will allow importing ts)
import { scoreTrade } from '../src/scoreTrade';

describe('scoreTrade integration', () => {
  before(async () => {
    // Initialize admin to use the emulator
    if (!admin.apps.length) {
      admin.initializeApp({ projectId: 'demo-project' });
    }
  });

  after(() => {
    test.cleanup();
  });

  it('writes disciplineScore and breakdown to journal entry', async () => {
    const db = admin.firestore();
    const journalRef = db.collection('journalEntries').doc('integration-test-journal');

    await journalRef.set({
      uid: 'test-user',
      strategyId: 'wheel',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      plannedEntryTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 600000)), // 10m ago
      stopLoss: 90,
      accountSize: 10000,
      contractSize: 100,
      maxRiskPercent: 2,
    });

    const wrapped = test.wrap(scoreTrade) as any;

    const plannedParams = {
      plannedEntryTime: new Date(Date.now() - 600000).toISOString(),
      stopLoss: 90,
      accountSize: 10000,
      contractSize: 100,
      maxRiskPercent: 2,
    };

    const executedParams = {
      entryPrice: 100,
      contracts: 1,
      executedAt: new Date().toISOString(),
    };

    // Call with auth context
    const res = await wrapped({ journalId: 'integration-test-journal', plannedParams, executedParams }, { auth: { uid: 'test-user' } });

    assert.ok(res);
    assert.ok(res.total !== undefined);

    const updated = await journalRef.get();
    const data = updated.data();
    assert.ok(data);
    assert.ok(typeof data?.disciplineScore === 'number');
    assert.ok(data?.disciplineBreakdown);
    assert.strictEqual(data?.scoredBy, 'test-user');
  });
});
