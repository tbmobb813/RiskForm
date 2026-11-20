import * as assert from "assert";
import {
  asArray,
  daysUntil,
  parseChain,
  parseExpirations,
  parseSpot,
  toIvPercent,
} from "../../src/tradier/normalize";

describe("asArray", () => {
  it("wraps a lone value and passes arrays through", () => {
    assert.deepStrictEqual(asArray(1), [1]);
    assert.deepStrictEqual(asArray([1, 2]), [1, 2]);
    assert.deepStrictEqual(asArray(null), []);
    assert.deepStrictEqual(asArray(undefined), []);
  });
});

describe("parseExpirations", () => {
  it("reads the plain date list", () => {
    assert.deepStrictEqual(
      parseExpirations({expirations: {date: ["2026-12-18", "2026-12-11"]}}),
      ["2026-12-11", "2026-12-18"]
    );
  });

  it("reads a single date returned as a string", () => {
    assert.deepStrictEqual(
      parseExpirations({expirations: {date: "2026-12-18"}}),
      ["2026-12-18"]
    );
  });

  it("reads the detailed shape, one entry or many", () => {
    assert.deepStrictEqual(
      parseExpirations({expirations: {expiration: {date: "2026-12-18"}}}),
      ["2026-12-18"]
    );
    assert.deepStrictEqual(
      parseExpirations({
        expirations: {
          expiration: [{date: "2027-01-15"}, {date: "2026-12-18"}],
        },
      }),
      ["2026-12-18", "2027-01-15"]
    );
  });

  it("drops duplicates and malformed dates", () => {
    assert.deepStrictEqual(
      parseExpirations({
        expirations: {date: ["2026-12-18", "2026-12-18", "12/18/2026", ""]},
      }),
      ["2026-12-18"]
    );
  });

  it("returns nothing for empty or unexpected input", () => {
    assert.deepStrictEqual(parseExpirations({expirations: null}), []);
    assert.deepStrictEqual(parseExpirations(null), []);
    assert.deepStrictEqual(parseExpirations("nope"), []);
  });
});

describe("parseSpot", () => {
  it("uses the last price, whether one quote or a list", () => {
    assert.strictEqual(parseSpot({quotes: {quote: {last: 101.5}}}), 101.5);
    assert.strictEqual(parseSpot({quotes: {quote: [{last: 99}]}}), 99);
  });

  it("falls back to the bid-ask midpoint, then the previous close", () => {
    assert.strictEqual(
      parseSpot({quotes: {quote: {last: null, bid: 10, ask: 12}}}),
      11
    );
    assert.strictEqual(
      parseSpot({quotes: {quote: {last: null, bid: null, ask: null, prevclose: 50}}}),
      50
    );
  });

  it("returns null for an unknown symbol", () => {
    assert.strictEqual(
      parseSpot({quotes: {unmatched_symbols: {symbol: "ZZZZ"}}}),
      null
    );
    assert.strictEqual(parseSpot({quotes: {quote: {last: null}}}), null);
    assert.strictEqual(parseSpot({}), null);
  });
});

describe("toIvPercent", () => {
  it("converts fractions and keeps percents", () => {
    assert.ok(Math.abs((toIvPercent(0.32) ?? 0) - 32) < 1e-9);
    assert.strictEqual(toIvPercent(32), 32);
    assert.strictEqual(toIvPercent(null), null);
    assert.strictEqual(toIvPercent(0), null);
  });
});

const put = (overrides: Record<string, unknown> = {}) => ({
  option_type: "put",
  strike: 95,
  expiration_date: "2026-12-18",
  bid: 1.2,
  ask: 1.3,
  open_interest: 500,
  volume: 40,
  greeks: {delta: -0.25, mid_iv: 0.32},
  ...overrides,
});

describe("parseChain", () => {
  it("normalizes a put with greeks", () => {
    const [q] = parseChain({options: {option: [put()]}}, "put");

    assert.strictEqual(q.right, "put");
    assert.strictEqual(q.strike, 95);
    assert.strictEqual(q.expiration, "2026-12-18");
    assert.strictEqual(q.bid, 1.2);
    assert.strictEqual(q.ask, 1.3);
    assert.strictEqual(q.delta, 0.25);
    assert.ok(Math.abs((q.ivPercent ?? 0) - 32) < 1e-9);
    assert.strictEqual(q.openInterest, 500);
    assert.strictEqual(q.volume, 40);
  });

  it("filters by right, or keeps both", () => {
    const json = {
      options: {option: [put(), put({option_type: "call", strike: 105})]},
    };
    assert.strictEqual(parseChain(json, "put").length, 1);
    assert.strictEqual(parseChain(json, "call").length, 1);
    assert.strictEqual(parseChain(json, "both").length, 2);
  });

  it("reads a lone option returned as an object", () => {
    assert.strictEqual(parseChain({options: {option: put()}}, "put").length, 1);
  });

  it("returns nothing when there are no options", () => {
    assert.deepStrictEqual(parseChain({options: null}, "put"), []);
    assert.deepStrictEqual(parseChain({}, "put"), []);
  });

  it("keeps missing greeks and data as null", () => {
    const [q] = parseChain(
      {
        options: {
          option: [
            put({
              greeks: null,
              ask: null,
              open_interest: null,
              volume: null,
            }),
          ],
        },
      },
      "put"
    );

    assert.strictEqual(q.delta, null);
    assert.strictEqual(q.ivPercent, null);
    assert.strictEqual(q.ask, null);
    assert.strictEqual(q.openInterest, null);
    assert.strictEqual(q.volume, null);
  });

  it("treats a null bid as zero", () => {
    const [q] = parseChain({options: {option: [put({bid: null, ask: 0.05})]}}, "put");
    assert.strictEqual(q.bid, 0);
    assert.strictEqual(q.ask, 0.05);
  });

  it("drops an ask that is below the bid", () => {
    const [q] = parseChain({options: {option: [put({bid: 1.5, ask: 1.2})]}}, "put");
    assert.strictEqual(q.ask, null);
  });

  it("skips rows that cannot be used", () => {
    const rows = [
      put({strike: null}),
      put({strike: 0}),
      put({expiration_date: "soon"}),
      put({option_type: "straddle"}),
      "garbage",
      put({strike: 90}),
    ];
    const quotes = parseChain({options: {option: rows}}, "put");
    assert.deepStrictEqual(
      quotes.map((q) => q.strike),
      [90]
    );
  });
});

describe("daysUntil", () => {
  it("counts calendar days by UTC date", () => {
    const now = new Date("2026-11-20T23:30:00Z");
    assert.strictEqual(daysUntil("2026-12-20", now), 30);
    assert.strictEqual(daysUntil("2026-11-20", now), 0);
    assert.strictEqual(daysUntil("2026-11-19", now), -1);
  });
});
