import {TradierClient, TradierError} from "./client";
import {
  NormalizedQuote,
  OptionRight,
  daysUntil,
  parseChain,
  parseExpirations,
  parseSpot,
} from "./normalize";

export interface OptionChainRequest {
  symbol: string;
  minDte: number;
  maxDte: number;
  /** Most expirations to fetch, soonest first. */
  maxExpirations: number;
  right: OptionRight | "both";
}

export interface OptionChainResult {
  symbol: string;
  spot: number;
  /** When the data was fetched, ISO 8601. */
  asOf: string;
  quotes: NormalizedQuote[];
  expirationsFetched: string[];
  /** True when more expirations matched than maxExpirations allowed. */
  truncated: boolean;
}

const CONCURRENCY = 3;

async function mapWithLimit<T, R>(
  items: T[],
  limit: number,
  fn: (item: T) => Promise<R>
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let next = 0;
  const workers = Array.from({length: Math.min(limit, items.length)}, async () => {
    while (next < items.length) {
      const i = next++;
      results[i] = await fn(items[i]);
    }
  });
  await Promise.all(workers);
  return results;
}

/**
 * Fetches the stock price and the option chains for expirations inside the
 * requested window. Uses 2 calls plus one per expiration.
 */
export async function fetchOptionChain(
  client: TradierClient,
  req: OptionChainRequest,
  now: Date = new Date()
): Promise<OptionChainResult> {
  const [quoteJson, expirationsJson] = await Promise.all([
    client.getQuote(req.symbol),
    client.getExpirations(req.symbol),
  ]);

  const spot = parseSpot(quoteJson);
  if (spot === null) {
    throw new TradierError("bad_request", `Unknown symbol ${req.symbol}.`);
  }

  const inWindow = parseExpirations(expirationsJson).filter((d) => {
    const dte = daysUntil(d, now);
    return dte >= Math.max(req.minDte, 1) && dte <= req.maxDte;
  });
  const chosen = inWindow.slice(0, req.maxExpirations);

  const chains = await mapWithLimit(chosen, CONCURRENCY, async (expiration) =>
    parseChain(await client.getChain(req.symbol, expiration), req.right)
  );

  return {
    symbol: req.symbol,
    spot,
    asOf: now.toISOString(),
    quotes: chains.flat(),
    expirationsFetched: chosen,
    truncated: inWindow.length > chosen.length,
  };
}
