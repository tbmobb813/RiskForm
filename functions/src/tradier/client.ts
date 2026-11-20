export type TradierErrorKind =
  | "auth"
  | "rate_limit"
  | "bad_request"
  | "unavailable";

export class TradierError extends Error {
  constructor(
    readonly kind: TradierErrorKind,
    message: string
  ) {
    super(message);
    this.name = "TradierError";
  }
}

export type FetchFn = (
  url: string,
  init: { headers: Record<string, string> }
) => Promise<{
  ok: boolean;
  status: number;
  text(): Promise<string>;
}>;

export const PRODUCTION_BASE_URL = "https://api.tradier.com/v1";
export const SANDBOX_BASE_URL = "https://sandbox.tradier.com/v1";

/** Thin, read-only client for the Tradier market data endpoints. */
export class TradierClient {
  private readonly baseUrl: string;

  constructor(
    private readonly token: string,
    private readonly fetchFn: FetchFn,
    baseUrl: string = PRODUCTION_BASE_URL
  ) {
    this.baseUrl = baseUrl.replace(/\/+$/, "");
  }

  getQuote(symbol: string): Promise<unknown> {
    return this.get("/markets/quotes", {symbols: symbol});
  }

  getExpirations(symbol: string): Promise<unknown> {
    return this.get("/markets/options/expirations", {symbol});
  }

  getChain(symbol: string, expiration: string): Promise<unknown> {
    return this.get("/markets/options/chains", {
      symbol,
      expiration,
      greeks: "true",
    });
  }

  private async get(
    path: string,
    params: Record<string, string>
  ): Promise<unknown> {
    const url = `${this.baseUrl}${path}?${new URLSearchParams(params)}`;

    let res;
    let body: string;
    try {
      res = await this.fetchFn(url, {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${this.token}`,
        },
      });
      body = await res.text();
    } catch {
      throw new TradierError("unavailable", "Could not reach Tradier.");
    }

    // Tradier reports an exceeded rate limit as HTTP 400 with a plain-text
    // "Quota Violation" body, not 429, so check the text before the status.
    if (res.status === 429 || body.includes("Quota Violation")) {
      throw new TradierError("rate_limit", "Tradier rate limit reached.");
    }
    if (res.status === 401 || res.status === 403) {
      throw new TradierError("auth", "Tradier rejected the access token.");
    }
    if (res.status >= 500) {
      throw new TradierError("unavailable", `Tradier error (HTTP ${res.status}).`);
    }
    if (!res.ok) {
      throw new TradierError("bad_request", `Tradier rejected the request (HTTP ${res.status}).`);
    }

    try {
      return JSON.parse(body);
    } catch {
      throw new TradierError("unavailable", "Tradier returned an unreadable response.");
    }
  }
}
