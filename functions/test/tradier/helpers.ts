import {FetchFn} from "../../src/tradier/client";

export interface Call {
  url: string;
  headers: Record<string, string>;
}

export interface FakeResponse {
  status?: number;
  body: unknown;
}

/** A fetch that answers from [respond] and records every request. */
export function fakeFetch(respond: (url: URL) => FakeResponse) {
  const calls: Call[] = [];
  const fn: FetchFn = async (url, init) => {
    calls.push({url, headers: init.headers});
    const r = respond(new URL(url));
    const status = r.status ?? 200;
    return {
      ok: status >= 200 && status < 300,
      status,
      text: async () =>
        typeof r.body === "string" ? r.body : JSON.stringify(r.body),
    };
  };
  return {fn, calls};
}
