import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const anthropicKey = defineSecret("ANTHROPIC_API_KEY");

const SIGNAL_SYSTEM_PROMPT = `You are an elite quantitative trading analyst and signal generation engine. You have expertise in:
- Options flow analysis and Greeks interpretation
- Technical analysis (price action, momentum, volatility regimes)
- Macro regime detection (Fed policy, yield curve, credit spreads, economic cycle)
- Fundamental analysis and earnings momentum
- Market microstructure and sentiment

Your job is to generate a structured, actionable trading signal for the given ticker. Use web search extensively to gather:
1. MACRO DATA: Current Fed funds rate, 2s10s yield curve, recent CPI/PCE, ISM data, unemployment trend
2. EQUITY/OPTIONS DATA: Current price, recent price action, options IV rank, put/call ratio, unusual options activity
3. FUNDAMENTAL/SENTIMENT DATA: Recent earnings, analyst ratings changes, insider activity, news sentiment

After gathering data, produce your signal in this EXACT JSON format (no markdown, no preamble, pure JSON):
{
  "ticker": "SYMBOL",
  "signal": "STRONG_BUY | BUY | NEUTRAL | SELL | STRONG_SELL",
  "confidence": 0-100,
  "timeframe": "1-5 DAYS | 1-4 WEEKS | 1-3 MONTHS",
  "entry_zone": "price range or condition",
  "target": "price target or % gain",
  "stop": "stop loss level",
  "thesis": "2-3 sentence core thesis",
  "macro_context": "1-2 sentences on macro tailwind/headwind",
  "options_edge": "specific options strategy if applicable, or null",
  "key_risks": ["risk1", "risk2", "risk3"],
  "data_sources_used": ["source1", "source2"],
  "regime": "RISK_ON | RISK_OFF | TRANSITIONAL",
  "catalyst": "upcoming catalyst or null",
  "macro_score": -100 to 100,
  "technical_score": -100 to 100,
  "sentiment_score": -100 to 100,
  "composite_score": -100 to 100
}`;

function buildUserPrompt(ticker: string): string {
  return `Generate a comprehensive autonomous trading signal for: ${ticker.toUpperCase()}

Search for and analyze:
1. Current price, recent 5-day price action, 20/50/200 day moving averages
2. Options data: IV rank, put/call ratio, notable flow
3. FRED macro: current fed funds rate, 2s10s spread, recent CPI, PMI
4. Finnhub: recent earnings beat/miss, analyst rating changes last 30 days, insider transactions
5. Any major news in last 5 days

After gathering all data, output ONLY the JSON signal object. No preamble. No markdown. Pure JSON.`;
}

function parseSignalJson(text: string): Record<string, unknown> | null {
  try {
    const clean = text.replace(/```json|```/g, "").trim();
    const match = clean.match(/\{[\s\S]*\}/);
    if (match) return JSON.parse(match[0]);
  } catch {
    // fall through
  }
  return null;
}

export const generateSignal = onCall(
  { secrets: [anthropicKey], timeoutSeconds: 120 },
  async (request) => {
    const ticker = request.data?.ticker;
    if (typeof ticker !== "string" || !ticker.trim()) {
      throw new HttpsError("invalid-argument", "ticker is required");
    }

    const apiKey = anthropicKey.value();

    const anthropicBody = {
      model: "claude-sonnet-4-20250514",
      max_tokens: 1500,
      system: SIGNAL_SYSTEM_PROMPT,
      tools: [{ type: "web_search_20250305", name: "web_search" }],
      messages: [{ role: "user", content: buildUserPrompt(ticker) }],
    };

    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify(anthropicBody),
    });

    if (!res.ok) {
      const err = await res.json() as { error?: { message?: string } };
      throw new HttpsError(
        "internal",
        err.error?.message ?? `Anthropic error: HTTP ${res.status}`
      );
    }

    const data = await res.json() as {
      content: Array<{ type: string; text?: string; input?: { query?: string } }>;
    };

    // Collect search queries used (for logging on Flutter side)
    const searchQueries = data.content
      .filter((b) => b.type === "tool_use")
      .map((b) => b.input?.query ?? "")
      .filter(Boolean);

    // Extract final text content
    const fullText = data.content
      .filter((b) => b.type === "text")
      .map((b) => b.text ?? "")
      .join("\n");

    const signal = parseSignalJson(fullText);
    if (!signal) {
      throw new HttpsError(
        "internal",
        `Could not parse signal JSON for ${ticker}. Raw: ${fullText.slice(0, 300)}`
      );
    }

    // Ensure ticker is normalized
    signal["ticker"] = ticker.toUpperCase();

    return { signal, searchQueries };
  }
);
