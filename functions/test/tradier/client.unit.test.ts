import * as assert from "assert";
import {
  PRODUCTION_BASE_URL,
  SANDBOX_BASE_URL,
  TradierClient,
  TradierError,
  TradierErrorKind,
} from "../../src/tradier/client";
import {fakeFetch} from "./helpers";

async function kindOf(promise: Promise<unknown>): Promise<TradierErrorKind> {
  try {
    await promise;
  } catch (e) {
    assert.ok(e instanceof TradierError, `expected TradierError, got ${e}`);
    return e.kind;
  }
  throw new Error("expected the call to fail");
}

describe("TradierClient requests", () => {
  it("sends the bearer token and asks for JSON", async () => {
    const {fn, calls} = fakeFetch(() => ({body: {quotes: {}}}));
    await new TradierClient("secret-token", fn).getQuote("AAPL");

    assert.strictEqual(calls[0].headers.Authorization, "Bearer secret-token");
    assert.strictEqual(calls[0].headers.Accept, "application/json");
  });

  it("builds the quote, expirations and chain URLs", async () => {
    const {fn, calls} = fakeFetch(() => ({body: {}}));
    const client = new TradierClient("t", fn);

    await client.getQuote("BRK.B");
    await client.getExpirations("AAPL");
    await client.getChain("AAPL", "2026-12-18");

    const [quote, expirations, chain] = calls.map((c) => new URL(c.url));
    assert.strictEqual(quote.origin + quote.pathname, `${PRODUCTION_BASE_URL}/markets/quotes`);
    assert.strictEqual(quote.searchParams.get("symbols"), "BRK.B");
    assert.strictEqual(expirations.pathname, "/v1/markets/options/expirations");
    assert.strictEqual(expirations.searchParams.get("symbol"), "AAPL");
    assert.strictEqual(chain.pathname, "/v1/markets/options/chains");
    assert.strictEqual(chain.searchParams.get("expiration"), "2026-12-18");
    assert.strictEqual(chain.searchParams.get("greeks"), "true");
  });

  it("uses the sandbox host when asked, ignoring a trailing slash", async () => {
    const {fn, calls} = fakeFetch(() => ({body: {}}));
    await new TradierClient("t", fn, `${SANDBOX_BASE_URL}/`).getQuote("AAPL");

    assert.ok(calls[0].url.startsWith("https://sandbox.tradier.com/v1/markets/quotes?"));
  });

  it("returns the parsed JSON body", async () => {
    const {fn} = fakeFetch(() => ({body: {hello: "world"}}));
    assert.deepStrictEqual(await new TradierClient("t", fn).getQuote("A"), {
      hello: "world",
    });
  });
});

describe("TradierClient errors", () => {
  const failing = (status: number, body: unknown) =>
    new TradierClient("t", fakeFetch(() => ({status, body})).fn).getQuote("A");

  it("reports a bad token as auth", async () => {
    assert.strictEqual(await kindOf(failing(401, "")), "auth");
    assert.strictEqual(await kindOf(failing(403, "")), "auth");
  });

  it("detects Tradier's rate limit, which arrives as HTTP 400 text", async () => {
    assert.strictEqual(
      await kindOf(failing(400, "Quota Violation: Expires 1799200800000")),
      "rate_limit"
    );
  });

  it("also treats a real 429 as a rate limit", async () => {
    assert.strictEqual(await kindOf(failing(429, "")), "rate_limit");
  });

  it("treats other 4xx responses as bad requests", async () => {
    assert.strictEqual(await kindOf(failing(400, {fault: "bad symbol"})), "bad_request");
    assert.strictEqual(await kindOf(failing(404, "")), "bad_request");
  });

  it("treats 5xx responses as unavailable", async () => {
    assert.strictEqual(await kindOf(failing(502, "")), "unavailable");
  });

  it("treats a network failure as unavailable", async () => {
    const client = new TradierClient("t", async () => {
      throw new Error("ECONNRESET");
    });
    assert.strictEqual(await kindOf(client.getQuote("A")), "unavailable");
  });

  it("treats an unreadable body as unavailable", async () => {
    assert.strictEqual(await kindOf(failing(200, "<html>oops</html>")), "unavailable");
  });

  it("never puts the token or response text in the error message", async () => {
    const client = new TradierClient(
      "super-secret",
      fakeFetch(() => ({status: 401, body: "token super-secret invalid"})).fn
    );
    try {
      await client.getQuote("A");
      assert.fail("should have thrown");
    } catch (e) {
      assert.ok(!(e as Error).message.includes("super-secret"));
    }
  });
});
