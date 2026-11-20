import * as assert from "assert";
import {HttpsError} from "firebase-functions/v2/https";
import {generateSignal} from "../src/generateSignal";

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
  let fetchCalls: string[];

  beforeEach(() => {
    fetchCalls = [];
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
});
