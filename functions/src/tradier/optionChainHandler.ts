import {HttpsError} from "firebase-functions/v2/https";
import {TradierError} from "./client";
import {OptionChainRequest, OptionChainResult} from "./optionChainService";
import {OptionRight} from "./normalize";
import {TtlCache} from "./ttlCache";

export interface HandlerDeps {
  /** UIDs allowed to use live data. An empty list allows nobody. */
  allowedUids: string[];
  fetchChain: (req: OptionChainRequest) => Promise<OptionChainResult>;
  /** Returns false when the user is over their hourly limit. */
  consumeQuota: (uid: string) => Promise<boolean>;
  cache: TtlCache<OptionChainResult>;
  logError: (message: string, error: unknown) => void;
}

const SYMBOL = /^[A-Z][A-Z0-9.-]{0,9}$/;
const MAX_DTE = 730;
const MAX_EXPIRATIONS = 8;

function integer(
  value: unknown,
  name: string,
  fallback: number,
  min: number,
  max: number
): number {
  if (value === undefined || value === null) return fallback;
  if (typeof value !== "number" || !Number.isInteger(value)) {
    throw new HttpsError("invalid-argument", `${name} must be a whole number.`);
  }
  if (value < min || value > max) {
    throw new HttpsError(
      "invalid-argument",
      `${name} must be between ${min} and ${max}.`
    );
  }
  return value;
}

export function parseRequest(data: unknown): OptionChainRequest {
  const d = (data ?? {}) as Record<string, unknown>;

  const symbol = typeof d.symbol === "string" ? d.symbol.trim().toUpperCase() : "";
  if (!SYMBOL.test(symbol)) {
    throw new HttpsError("invalid-argument", "A valid stock symbol is required.");
  }

  const minDte = integer(d.minDte, "minDte", 21, 0, MAX_DTE);
  const maxDte = integer(d.maxDte, "maxDte", 60, 0, MAX_DTE);
  if (maxDte < minDte) {
    throw new HttpsError("invalid-argument", "maxDte must not be below minDte.");
  }
  const maxExpirations = integer(
    d.maxExpirations,
    "maxExpirations",
    6,
    1,
    MAX_EXPIRATIONS
  );

  const right = d.right ?? "put";
  if (right !== "put" && right !== "call" && right !== "both") {
    throw new HttpsError("invalid-argument", "right must be put, call or both.");
  }

  return {symbol, minDte, maxDte, maxExpirations, right: right as OptionRight | "both"};
}

function cacheKey(r: OptionChainRequest): string {
  return [r.symbol, r.right, r.minDte, r.maxDte, r.maxExpirations].join("|");
}

function toHttpsError(error: unknown): HttpsError {
  if (error instanceof HttpsError) return error;
  if (error instanceof TradierError) {
    switch (error.kind) {
      case "rate_limit":
        return new HttpsError(
          "resource-exhausted",
          "Live data is busy. Try again in a minute."
        );
      case "bad_request":
        return new HttpsError("invalid-argument", error.message);
      case "auth":
      case "unavailable":
        return new HttpsError(
          "unavailable",
          "Live data is temporarily unavailable."
        );
    }
  }
  return new HttpsError("internal", "Could not load the option chain.");
}

export async function handleGetOptionChain(
  deps: HandlerDeps,
  auth: {uid: string} | undefined,
  data: unknown
): Promise<OptionChainResult> {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in to load live option data.");
  }
  if (!deps.allowedUids.includes(auth.uid)) {
    throw new HttpsError(
      "permission-denied",
      "Live option data is not enabled for this account."
    );
  }

  const req = parseRequest(data);

  const key = cacheKey(req);
  const cached = deps.cache.get(key);
  if (cached) return cached;

  if (!(await deps.consumeQuota(auth.uid))) {
    throw new HttpsError(
      "resource-exhausted",
      "You have reached the hourly limit for live option data."
    );
  }

  try {
    const result = await deps.fetchChain(req);
    deps.cache.set(key, result);
    return result;
  } catch (error) {
    deps.logError(`getOptionChain failed for ${req.symbol}`, error);
    throw toHttpsError(error);
  }
}
