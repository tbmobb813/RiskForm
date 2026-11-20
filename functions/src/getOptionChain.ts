import {logger} from "firebase-functions";
import {defineSecret, defineString} from "firebase-functions/params";
import {onCall} from "firebase-functions/v2/https";
import {consumeHourlyQuota} from "./rateLimit";
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

const consumeQuota = (uid: string) =>
  consumeHourlyQuota({
    collection: "tradierUsage",
    uid,
    limit: REQUESTS_PER_HOUR,
  });

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
