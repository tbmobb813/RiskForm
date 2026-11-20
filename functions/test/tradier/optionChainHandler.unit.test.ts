import * as assert from "assert";
import {HttpsError} from "firebase-functions/v2/https";
import {TradierError} from "../../src/tradier/client";
import {HandlerDeps, handleGetOptionChain} from "../../src/tradier/optionChainHandler";
import {OptionChainRequest, OptionChainResult} from "../../src/tradier/optionChainService";
import {TtlCache} from "../../src/tradier/ttlCache";

const RESULT: OptionChainResult = {
  symbol: "AAPL",
  spot: 100,
  asOf: "2026-11-20T15:00:00.000Z",
  quotes: [],
  expirationsFetched: [],
  truncated: false,
};

function setup(over: Partial<HandlerDeps> = {}) {
  const fetched: OptionChainRequest[] = [];
  const quotaUsers: string[] = [];
  const logged: string[] = [];
  const deps: HandlerDeps = {
    allowedUids: ["owner"],
    fetchChain: async (req) => {
      fetched.push(req);
      return {...RESULT, symbol: req.symbol};
    },
    consumeQuota: async (uid) => {
      quotaUsers.push(uid);
      return true;
    },
    cache: new TtlCache<OptionChainResult>(60_000, 10),
    logError: (m) => logged.push(m),
    ...over,
  };
  return {deps, fetched, quotaUsers, logged};
}

const owner = {uid: "owner"};

async function codeOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (e) {
    assert.ok(e instanceof HttpsError, `expected HttpsError, got ${e}`);
    return e.code;
  }
  throw new Error("expected the call to fail");
}

describe("handleGetOptionChain access", () => {
  it("requires sign-in", async () => {
    const {deps, fetched} = setup();
    assert.strictEqual(
      await codeOf(handleGetOptionChain(deps, undefined, {symbol: "AAPL"})),
      "unauthenticated"
    );
    assert.strictEqual(fetched.length, 0);
  });

  it("denies users who are not on the allow-list", async () => {
    const {deps, fetched} = setup();
    assert.strictEqual(
      await codeOf(handleGetOptionChain(deps, {uid: "stranger"}, {symbol: "AAPL"})),
      "permission-denied"
    );
    assert.strictEqual(fetched.length, 0);
  });

  it("denies everyone when the allow-list is empty", async () => {
    const {deps} = setup({allowedUids: []});
    assert.strictEqual(
      await codeOf(handleGetOptionChain(deps, owner, {symbol: "AAPL"})),
      "permission-denied"
    );
  });

  it("checks access before looking at the input", async () => {
    const {deps} = setup();
    assert.strictEqual(
      await codeOf(handleGetOptionChain(deps, {uid: "stranger"}, {symbol: "!!"})),
      "permission-denied"
    );
  });
});

describe("handleGetOptionChain input", () => {
  it("applies defaults and normalizes the symbol", async () => {
    const {deps, fetched} = setup();
    await handleGetOptionChain(deps, owner, {symbol: " aapl "});

    assert.deepStrictEqual(fetched[0], {
      symbol: "AAPL",
      minDte: 21,
      maxDte: 60,
      maxExpirations: 6,
      right: "put",
    });
  });

  it("accepts class-share symbols", async () => {
    const {deps, fetched} = setup();
    await handleGetOptionChain(deps, owner, {symbol: "brk.b"});
    assert.strictEqual(fetched[0].symbol, "BRK.B");
  });

  const bad: Array<[string, unknown]> = [
    ["a missing symbol", {}],
    ["no input at all", undefined],
    ["a symbol with spaces", {symbol: "A B"}],
    ["a symbol that is too long", {symbol: "ABCDEFGHIJK"}],
    ["a symbol starting with a digit", {symbol: "1ABC"}],
    ["a non-number minDte", {symbol: "A", minDte: "30"}],
    ["a fractional maxDte", {symbol: "A", maxDte: 30.5}],
    ["a negative minDte", {symbol: "A", minDte: -1}],
    ["an enormous maxDte", {symbol: "A", maxDte: 5000}],
    ["maxDte below minDte", {symbol: "A", minDte: 40, maxDte: 20}],
    ["zero expirations", {symbol: "A", maxExpirations: 0}],
    ["too many expirations", {symbol: "A", maxExpirations: 9}],
    ["an unknown right", {symbol: "A", right: "straddle"}],
  ];
  for (const [name, input] of bad) {
    it(`rejects ${name}`, async () => {
      const {deps, fetched} = setup();
      assert.strictEqual(
        await codeOf(handleGetOptionChain(deps, owner, input)),
        "invalid-argument"
      );
      assert.strictEqual(fetched.length, 0);
    });
  }
});

describe("handleGetOptionChain caching and quota", () => {
  it("counts one request against the quota per fetch", async () => {
    const {deps, quotaUsers} = setup();
    await handleGetOptionChain(deps, owner, {symbol: "AAPL"});
    assert.deepStrictEqual(quotaUsers, ["owner"]);
  });

  it("serves a repeat request from cache without fetching or using quota", async () => {
    const {deps, fetched, quotaUsers} = setup();
    await handleGetOptionChain(deps, owner, {symbol: "AAPL"});
    await handleGetOptionChain(deps, owner, {symbol: "aapl"});

    assert.strictEqual(fetched.length, 1);
    assert.strictEqual(quotaUsers.length, 1);
  });

  it("treats different parameters as different requests", async () => {
    const {deps, fetched} = setup();
    await handleGetOptionChain(deps, owner, {symbol: "AAPL"});
    await handleGetOptionChain(deps, owner, {symbol: "AAPL", maxDte: 90});
    await handleGetOptionChain(deps, owner, {symbol: "MSFT"});

    assert.strictEqual(fetched.length, 3);
  });

  it("refuses when the hourly quota is used up, without fetching", async () => {
    const {deps, fetched} = setup({consumeQuota: async () => false});
    assert.strictEqual(
      await codeOf(handleGetOptionChain(deps, owner, {symbol: "AAPL"})),
      "resource-exhausted"
    );
    assert.strictEqual(fetched.length, 0);
  });

  it("does not cache a failed fetch", async () => {
    let calls = 0;
    const {deps} = setup({
      fetchChain: async () => {
        calls++;
        if (calls === 1) throw new TradierError("unavailable", "down");
        return RESULT;
      },
    });

    await codeOf(handleGetOptionChain(deps, owner, {symbol: "AAPL"}));
    const second = await handleGetOptionChain(deps, owner, {symbol: "AAPL"});
    assert.strictEqual(second.symbol, "AAPL");
    assert.strictEqual(calls, 2);
  });
});

describe("handleGetOptionChain error mapping", () => {
  const failWith = (e: unknown) =>
    setup({
      fetchChain: async () => {
        throw e;
      },
    });

  it("maps a rate limit to resource-exhausted", async () => {
    const {deps} = failWith(new TradierError("rate_limit", "x"));
    assert.strictEqual(
      await codeOf(handleGetOptionChain(deps, owner, {symbol: "AAPL"})),
      "resource-exhausted"
    );
  });

  it("maps an unknown symbol to invalid-argument and shows the reason", async () => {
    const {deps} = failWith(new TradierError("bad_request", "Unknown symbol ZZZZ."));
    try {
      await handleGetOptionChain(deps, owner, {symbol: "ZZZZ"});
      assert.fail("should have thrown");
    } catch (e) {
      assert.ok(e instanceof HttpsError);
      assert.strictEqual(e.code, "invalid-argument");
      assert.ok(e.message.includes("ZZZZ"));
    }
  });

  it("hides token problems and outages behind a generic unavailable error", async () => {
    for (const kind of ["auth", "unavailable"] as const) {
      const {deps, logged} = failWith(
        new TradierError(kind, "Tradier rejected the access token.")
      );
      try {
        await handleGetOptionChain(deps, owner, {symbol: "AAPL"});
        assert.fail("should have thrown");
      } catch (e) {
        assert.ok(e instanceof HttpsError);
        assert.strictEqual(e.code, "unavailable");
        assert.ok(!/token|tradier/i.test(e.message), e.message);
        assert.strictEqual(logged.length, 1);
      }
    }
  });

  it("maps anything unexpected to internal without leaking details", async () => {
    const {deps} = failWith(new Error("secret stack detail"));
    try {
      await handleGetOptionChain(deps, owner, {symbol: "AAPL"});
      assert.fail("should have thrown");
    } catch (e) {
      assert.ok(e instanceof HttpsError);
      assert.strictEqual(e.code, "internal");
      assert.ok(!e.message.includes("secret"));
    }
  });
});

describe("TtlCache", () => {
  it("expires entries after the time limit", () => {
    let now = 0;
    const cache = new TtlCache<number>(1000, 10, () => now);
    cache.set("a", 1);
    now = 999;
    assert.strictEqual(cache.get("a"), 1);
    now = 1000;
    assert.strictEqual(cache.get("a"), undefined);
  });

  it("drops the oldest entry when full", () => {
    const cache = new TtlCache<number>(1000, 2, () => 0);
    cache.set("a", 1);
    cache.set("b", 2);
    cache.set("c", 3);
    assert.strictEqual(cache.get("a"), undefined);
    assert.strictEqual(cache.get("b"), 2);
    assert.strictEqual(cache.get("c"), 3);
  });
});
