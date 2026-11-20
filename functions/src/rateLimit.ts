import * as admin from "firebase-admin";

type Db = Pick<admin.firestore.Firestore, "doc" | "runTransaction">;

export interface QuotaOptions {
  /** Firestore collection that holds the counters, for example "signalUsage". */
  collection: string;
  uid: string;
  /** Most requests allowed per user per clock hour. */
  limit: number;
  now?: () => number;
  /** Defaults to the Admin SDK's Firestore. */
  db?: Db;
}

/**
 * Counts one request against the user's current hour. Returns false, without
 * counting, when the user is already at the limit.
 *
 * Counters live in `<collection>/<uid>_<hours since epoch>` and are only ever
 * touched by Cloud Functions, so client access stays denied by the rules.
 */
export async function consumeHourlyQuota(opts: QuotaOptions): Promise<boolean> {
  const db = opts.db ?? admin.firestore();
  const hour = Math.floor((opts.now ?? Date.now)() / 3_600_000);
  const ref = db.doc(`${opts.collection}/${opts.uid}_${hour}`);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = (snap.get("count") as number | undefined) ?? 0;
    if (count >= opts.limit) return false;
    tx.set(ref, {uid: opts.uid, hour, count: count + 1}, {merge: true});
    return true;
  });
}
