import * as assert from "assert";
import {TradierClient, TradierError} from "../../src/tradier/client";
import {fetchOptionChain} from "../../src/tradier/optionChainService";
import {fakeFetch} from "./helpers";

const NOW = new Date("2026-11-20T15:00:00Z");

// Expirations relative to NOW: 0, 7, 30, 37, 44, 51, 58, 65, 72 days out.
const EXPIRATIONS = [
  "2026-11-20", "2026-11-27", "2026-12-20", "2026-12-27", "2027-01-03",
  "2027-01-10", "2027-01-17", "2027-01-24", "2027-01-31",
];

const optionFor = (expiration: string) => ({
  option_type: "put",
  strike: 95,
  expiration_date: expiration,
  bid: 1,
  ask: 1.1,
  greeks: {delta: -0.2, mid_iv: 0.3},
});

function market(opts: {spot?: number | null; track?: {inFlight: number; max: number}} = {}) {
  return fakeFetch((url) => {
    if (url.pathname.endsWith("/quotes")) {
      return {
        body:
          opts.spot === null ?
            {quotes: {unmatched_symbols: {symbol: "ZZZZ"}}} :
            {quotes: {quote: {last: opts.spot ?? 100}}},
      };
    }
    if (url.pathname.endsWith("/expirations")) {
      return {body: {expirations: {date: EXPIRATIONS}}};
    }
    const expiration = url.searchParams.get("expiration") ?? "";
    return {body: {options: {option: [optionFor(expiration)]}}};
  });
}

const request = (over: Partial<Parameters<typeof fetchOptionChain>[1]> = {}) => ({
  symbol: "XYZ",
  minDte: 21,
  maxDte: 60,
  maxExpirations: 6,
  right: "put" as const,
  ...over,
});

describe("fetchOptionChain", () => {
  it("fetches only expirations inside the window, soonest first", async () => {
    const {fn} = market();
    const result = await fetchOptionChain(new TradierClient("t", fn), request(), NOW);

    assert.deepStrictEqual(result.expirationsFetched, [
      "2026-12-20", "2026-12-27", "2027-01-03", "2027-01-10", "2027-01-17",
    ]);
    assert.strictEqual(result.truncated, false);
    assert.strictEqual(result.spot, 100);
    assert.strictEqual(result.asOf, NOW.toISOString());
    assert.strictEqual(result.quotes.length, 5);
  });

  it("caps the number of expirations and says it truncated", async () => {
    const {fn, calls} = market();
    const result = await fetchOptionChain(
      new TradierClient("t", fn),
      request({maxExpirations: 2}),
      NOW
    );

    assert.deepStrictEqual(result.expirationsFetched, ["2026-12-20", "2026-12-27"]);
    assert.strictEqual(result.truncated, true);
    // 1 quote + 1 expirations + 2 chains.
    assert.strictEqual(calls.length, 4);
  });

  it("never fetches an expiration that is today", async () => {
    const {fn} = market();
    const result = await fetchOptionChain(
      new TradierClient("t", fn),
      request({minDte: 0, maxDte: 10}),
      NOW
    );

    assert.deepStrictEqual(result.expirationsFetched, ["2026-11-27"]);
  });

  it("returns no quotes when nothing falls in the window", async () => {
    const {fn} = market();
    const result = await fetchOptionChain(
      new TradierClient("t", fn),
      request({minDte: 200, maxDte: 300}),
      NOW
    );

    assert.deepStrictEqual(result.quotes, []);
    assert.deepStrictEqual(result.expirationsFetched, []);
  });

  it("rejects an unknown symbol", async () => {
    const {fn} = market({spot: null});
    await assert.rejects(
      fetchOptionChain(new TradierClient("t", fn), request({symbol: "ZZZZ"}), NOW),
      (e: unknown) =>
        e instanceof TradierError &&
        e.kind === "bad_request" &&
        e.message.includes("ZZZZ")
    );
  });

  it("limits how many chain requests run at once", async () => {
    let inFlight = 0;
    let max = 0;
    const base = market();
    const client = new TradierClient("t", async (url, init) => {
      if (url.includes("/chains")) {
        inFlight++;
        max = Math.max(max, inFlight);
        await new Promise((r) => setTimeout(r, 5));
        inFlight--;
      }
      return base.fn(url, init);
    });

    await fetchOptionChain(client, request({maxExpirations: 8, maxDte: 100}), NOW);

    assert.ok(max >= 2, `expected some parallelism, saw ${max}`);
    assert.ok(max <= 3, `expected at most 3 at once, saw ${max}`);
  });

  it("passes a Tradier failure through unchanged", async () => {
    const client = new TradierClient(
      "t",
      fakeFetch(() => ({status: 401, body: ""})).fn
    );
    await assert.rejects(
      fetchOptionChain(client, request(), NOW),
      (e: unknown) => e instanceof TradierError && e.kind === "auth"
    );
  });
});
