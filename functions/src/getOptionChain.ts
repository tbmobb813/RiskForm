import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {defineSecret, defineString} from "firebase-functions/params";
import {onCall} from "firebase-functions/v2/https";
import {
  PRODUCTION_BASE_URL,
  SANDBOX_BASE_URL,
  TradierClient,
} from "./tradier/client";
import {handleGetOptionChain} from "./tradier/optionChainHandler";
import {
  OptionChainResult,
  fetchOptionChain,
} from "./tradier/optionChainService";
import {TtlCache} from "./tradier/ttlCache";

const tradierToken = defineSecret("TRADIER_TOKEN");
const tradierEnv = defineString("TRADIER_ENV", {default: "production"});
const allowedUidsParam = defineString("TRADIER_ALLOWED_UIDS", {default: ""});

const REQUESTS_PER_HOUR = 30;
const cache = new TtlCache<OptionChainResult>(60_000, 50);

/** Counts a request against the user's hour. Returns false when over the limit. */
async function consumeQuota(uid: string): Promise<boolean> {
  const db = admin.firestore();
  const hour = Math.floor(Date.now() / 3_600_000);
  const ref = db.doc(`tradierUsage/${uid}_${hour}`);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = (snap.get("count") as number | undefined) ?? 0;
    if (count >= REQUESTS_PER_HOUR) return false;
    tx.set(ref, {uid, hour, count: count + 1}, {merge: true});
    return true;
  });
}

/**
 * Loads a stock price and option chains from Tradier for the signed-in user.
 * The token never leaves the server. Access is limited to the UIDs listed in
 * TRADIER_ALLOWED_UIDS because Tradier market data is licensed for the
 * account holder, not for redistribution.
 */
export const getOptionChain = onCall(
  {secrets: [tradierToken], timeoutSeconds: 60},
  (request) => {
    const baseUrl =
      tradierEnv.value() === "sandbox" ? SANDBOX_BASE_URL : PRODUCTION_BASE_URL;

    return handleGetOptionChain(
      {
        allowedUids: allowedUidsParam
          .value()
          .split(",")
          .map((u) => u.trim())
          .filter(Boolean),
        fetchChain: (req) =>
          fetchOptionChain(
            new TradierClient(
              tradierToken.value(),
              (url, init) => fetch(url, init),
              baseUrl
            ),
            req
          ),
        consumeQuota,
        cache,
        logError: (message, error) => logger.error(message, error),
      },
      request.auth,
      request.data
    );
  }
);
