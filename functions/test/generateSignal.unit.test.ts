import * as assert from "assert";
import {HttpsError} from "firebase-functions/v2/https";
import {generateSignal, signalDeps} from "../src/generateSignal";

type Request = Parameters<typeof generateSignal.run>[0];

const call = (data: unknown, auth?: {uid: string}) =>
  generateSignal.run({
    data,
    auth,
    acceptsStreaming: false,
    rawRequest: {},
  } as unknown as Request);

async function codeOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (e) {
    assert.ok(e instanceof HttpsError, `expected HttpsError, got ${e}`);
    return e.code;
  }
  throw new Error("expected the call to fail");
}

describe("generateSignal", () => {
  const realFetch = globalThis.fetch;
  const realConsumeQuota = signalDeps.consumeQuota;
  let fetchCalls: string[];
  let quotaUsers: string[];
  let quotaAllows: boolean;

  beforeEach(() => {
    fetchCalls = [];
    quotaUsers = [];
    quotaAllows = true;
    signalDeps.consumeQuota = async (uid) => {
      quotaUsers.push(uid);
      return quotaAllows;
    };
    process.env.ANTHROPIC_API_KEY = "test-key";
    globalThis.fetch = (async (url: string | URL | Request) => {
      fetchCalls.push(String(url));
      return {
        ok: true,
        status: 200,
        json: async () => ({
          content: [{type: "text", text: "{\"signal\":\"BUY\",\"confidence\":70}"}],
        }),
      };
    }) as unknown as typeof fetch;
  });

  afterEach(() => {
    signalDeps.consumeQuota = realConsumeQuota;
    globalThis.fetch = realFetch;
    delete process.env.ANTHROPIC_API_KEY;
  });

  it("rejects a caller who is not signed in", async () => {
    assert.strictEqual(await codeOf(call({ticker: "AAPL"})), "unauthenticated");
  });

  it("never reaches Anthropic for a caller who is not signed in", async () => {
    await codeOf(call({ticker: "AAPL"}));
    assert.deepStrictEqual(fetchCalls, []);
  });

  it("checks sign-in before looking at the input", async () => {
    assert.strictEqual(await codeOf(call({})), "unauthenticated");
    assert.strictEqual(await codeOf(call(undefined)), "unauthenticated");
  });

  it("still validates input for a signed-in caller", async () => {
    assert.strictEqual(await codeOf(call({}, {uid: "u1"})), "invalid-argument");
    assert.deepStrictEqual(fetchCalls, []);
  });

  it("still generates a signal for a signed-in caller", async () => {
    const result = (await call({ticker: "aapl"}, {uid: "u1"})) as {
      signal: Record<string, unknown>;
    };

    assert.strictEqual(fetchCalls.length, 1);
    assert.ok(fetchCalls[0].startsWith("https://api.anthropic.com/"));
    assert.strictEqual(result.signal.ticker, "AAPL");
    assert.strictEqual(result.signal.signal, "BUY");
  });
  describe("hourly limit", () => {
    it("refuses a signed-in caller who is over the limit", async () => {
      quotaAllows = false;
      assert.strictEqual(
        await codeOf(call({ticker: "AAPL"}, {uid: "u1"})),
        "resource-exhausted"
      );
    });

    it("never reaches Anthropic when over the limit", async () => {
      quotaAllows = false;
      await codeOf(call({ticker: "AAPL"}, {uid: "u1"}));
      assert.deepStrictEqual(fetchCalls, []);
    });

    it("counts one request against the caller's own quota", async () => {
      await call({ticker: "AAPL"}, {uid: "u1"});
      assert.deepStrictEqual(quotaUsers, ["u1"]);
    });

    it("does not count a caller who is not signed in", async () => {
      await codeOf(call({ticker: "AAPL"}));
      assert.deepStrictEqual(quotaUsers, []);
    });

    it("does not count a request with invalid input", async () => {
      await codeOf(call({}, {uid: "u1"}));
      assert.deepStrictEqual(quotaUsers, []);
    });

    it("explains the limit in plain words", async () => {
      quotaAllows = false;
      try {
        await call({ticker: "AAPL"}, {uid: "u1"});
        assert.fail("should have thrown");
      } catch (e) {
        assert.ok(e instanceof HttpsError);
        assert.ok(e.message.includes("hourly limit"));
      }
    });
  });
});
