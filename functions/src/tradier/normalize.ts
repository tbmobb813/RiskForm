/**
 * Pure helpers that turn Tradier's JSON into the compact shape the app uses.
 * Tradier returns a lone item as an object instead of a one-element array and
 * uses null for missing data, so every reader here tolerates both.
 */

export type OptionRight = "put" | "call";

export interface NormalizedQuote {
  right: OptionRight;
  strike: number;
  /** YYYY-MM-DD */
  expiration: string;
  bid: number;
  /** Null when missing or crossed below the bid. */
  ask: number | null;
  /** Absolute delta between 0 and 1. */
  delta: number | null;
  /** Implied volatility in percent, for example 32 for 32%. */
  ivPercent: number | null;
  openInterest: number | null;
  volume: number | null;
}

type Json = Record<string, unknown>;

export function asArray<T>(value: T | T[] | null | undefined): T[] {
  if (value === null || value === undefined) return [];
  return Array.isArray(value) ? value : [value];
}

function asRecord(value: unknown): Json | null {
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    (value as Json) :
    null;
}

function num(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim() !== "") {
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/** Valid expiration dates from the expirations endpoint, in any of its shapes. */
export function parseExpirations(json: unknown): string[] {
  const expirations = asRecord(asRecord(json)?.expirations);
  if (!expirations) return [];

  const dates: string[] = [];
  for (const d of asArray<unknown>(expirations.date as unknown)) {
    if (typeof d === "string") dates.push(d);
  }
  for (const e of asArray<unknown>(expirations.expiration as unknown)) {
    if (typeof e === "string") dates.push(e);
    const date = asRecord(e)?.date;
    if (typeof date === "string") dates.push(date);
  }
  return [...new Set(dates.filter((d) => ISO_DATE.test(d)))].sort();
}

/**
 * The stock price from a quotes response: last trade, else the bid-ask
 * midpoint, else the previous close. Null when the symbol is unknown.
 */
export function parseSpot(json: unknown): number | null {
  const quote = asRecord(asArray<unknown>(asRecord(asRecord(json)?.quotes)?.quote as unknown)[0]);
  if (!quote) return null;

  const last = num(quote.last);
  if (last !== null && last > 0) return last;

  const bid = num(quote.bid);
  const ask = num(quote.ask);
  if (bid !== null && ask !== null && bid > 0 && ask >= bid) {
    return (bid + ask) / 2;
  }

  const close = num(quote.prevclose) ?? num(quote.close);
  return close !== null && close > 0 ? close : null;
}

/** IV is a fraction (0.32) from some feeds and a percent (32) from others. */
export function toIvPercent(raw: number | null): number | null {
  if (raw === null || raw <= 0) return null;
  return raw <= 3 ? raw * 100 : raw;
}

/** Option quotes from a chains response, optionally limited to one right. */
export function parseChain(
  json: unknown,
  right: OptionRight | "both"
): NormalizedQuote[] {
  const options = asRecord(asRecord(json)?.options);
  if (!options) return [];

  const quotes: NormalizedQuote[] = [];
  for (const raw of asArray<unknown>(options.option as unknown)) {
    const o = asRecord(raw);
    if (!o) continue;

    const optionType = o.option_type;
    if (optionType !== "put" && optionType !== "call") continue;
    if (right !== "both" && optionType !== right) continue;

    const strike = num(o.strike);
    const expiration = o.expiration_date;
    if (strike === null || strike <= 0) continue;
    if (typeof expiration !== "string" || !ISO_DATE.test(expiration)) continue;

    const bid = num(o.bid) ?? 0;
    const rawAsk = num(o.ask);
    const greeks = asRecord(o.greeks);
    const delta = num(greeks?.delta);
    const oi = num(o.open_interest);
    const volume = num(o.volume);

    quotes.push({
      right: optionType,
      strike,
      expiration,
      bid: bid < 0 ? 0 : bid,
      ask: rawAsk !== null && rawAsk >= bid ? rawAsk : null,
      delta: delta === null ? null : Math.abs(delta),
      ivPercent: toIvPercent(num(greeks?.mid_iv)),
      openInterest: oi === null ? null : Math.round(oi),
      volume: volume === null ? null : Math.round(volume),
    });
  }
  return quotes;
}

/** Calendar days from [from] to the YYYY-MM-DD date, by UTC date. */
export function daysUntil(isoDate: string, from: Date): number {
  const [y, m, d] = isoDate.split("-").map(Number);
  const target = Date.UTC(y, m - 1, d);
  const start = Date.UTC(from.getUTCFullYear(), from.getUTCMonth(), from.getUTCDate());
  return Math.round((target - start) / 86400000);
}
