import * as assert from "assert";
import {consumeHourlyQuota} from "../src/rateLimit";

type Doc = Record<string, unknown>;

/** Just enough of Firestore for the quota counter. */
class FakeDb {
  readonly docs = new Map<string, Doc>();

  doc(path: string) {
    return {path};
  }

  async runTransaction<T>(
    fn: (tx: {
      get(ref: {path: string}): Promise<{get(field: string): unknown}>;
      set(ref: {path: string}, value: Doc, options?: unknown): void;
    }) => Promise<T>
  ): Promise<T> {
    return fn({
      get: async (ref) => ({get: (field) => this.docs.get(ref.path)?.[field]}),
      set: (ref, value) => {
        this.docs.set(ref.path, {...(this.docs.get(ref.path) ?? {}), ...value});
      },
    });
  }
}

const HOUR = 3_600_000;

function quota(db: FakeDb, over: Partial<Parameters<typeof consumeHourlyQuota>[0]> = {}) {
  return consumeHourlyQuota({
    collection: "signalUsage",
    uid: "u1",
    limit: 3,
    now: () => 10 * HOUR + 5,
    db: db as unknown as Parameters<typeof consumeHourlyQuota>[0]["db"],
    ...over,
  });
}

describe("consumeHourlyQuota", () => {
  it("allows requests up to the limit, then refuses", async () => {
    const db = new FakeDb();
    assert.strictEqual(await quota(db), true);
    assert.strictEqual(await quota(db), true);
    assert.strictEqual(await quota(db), true);
    assert.strictEqual(await quota(db), false);
    assert.strictEqual(await quota(db), false);
  });

  it("does not count a refused request", async () => {
    const db = new FakeDb();
    for (let i = 0; i < 6; i++) await quota(db);
    assert.strictEqual(db.docs.get("signalUsage/u1_10")?.count, 3);
  });

  it("keeps each user's count separate", async () => {
    const db = new FakeDb();
    for (let i = 0; i < 3; i++) await quota(db);
    assert.strictEqual(await quota(db), false);
    assert.strictEqual(await quota(db, {uid: "u2"}), true);
  });

  it("starts fresh in the next hour", async () => {
    const db = new FakeDb();
    for (let i = 0; i < 3; i++) await quota(db);
    assert.strictEqual(await quota(db), false);
    assert.strictEqual(await quota(db, {now: () => 11 * HOUR}), true);
  });

  it("still counts within the same hour until its last millisecond", async () => {
    const db = new FakeDb();
    for (let i = 0; i < 3; i++) await quota(db);
    assert.strictEqual(await quota(db, {now: () => 11 * HOUR - 1}), false);
  });

  it("keeps features in separate collections", async () => {
    const db = new FakeDb();
    for (let i = 0; i < 3; i++) await quota(db);
    assert.strictEqual(await quota(db, {collection: "tradierUsage"}), true);
  });

  it("records who and when on the counter", async () => {
    const db = new FakeDb();
    await quota(db);
    assert.deepStrictEqual(db.docs.get("signalUsage/u1_10"), {
      uid: "u1",
      hour: 10,
      count: 1,
    });
  });

  it("refuses everything when the limit is zero", async () => {
    assert.strictEqual(await quota(new FakeDb(), {limit: 0}), false);
  });
});
