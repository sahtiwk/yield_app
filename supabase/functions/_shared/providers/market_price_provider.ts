import { fetchJson, finite } from "./http.ts";

export function parseMarketRecord(row: Record<string, unknown>, now: number) {
  const parts = String(row.arrival_date).split("/").map(Number);
  if (parts.length !== 3 || parts.some((v) => !Number.isInteger(v))) {
    throw new Error("Invalid price date");
  }
  const [day, month, year] = parts;
  const stamp = Date.UTC(year, month - 1, day);
  const date = new Date(stamp);
  if (
    date.getUTCDate() !== day || date.getUTCMonth() !== month - 1 ||
    date.getUTCFullYear() !== year || stamp > now || now - stamp > 48 * 3600000
  ) {
    throw new Error("Stale or invalid price date");
  }
  // The configured Agmarknet resource reports INR per quintal (100 kg).
  const price = finite(row.modal_price) / 100;
  if (price <= 0) throw new Error("Invalid market price");
  return {
    price_per_kg: price,
    observed_for: date.toISOString(),
    source_name: "Agmarknet / data.gov.in",
    source_type: "live",
  };
}

export async function marketPrice(
  commodity: string,
  market: string,
  key: string | undefined,
  resource: string | undefined,
  now: number,
) {
  if (!key || !resource || !/^[a-f0-9-]{36}$/.test(resource)) {
    throw new Error("Market provider is not configured");
  }
  const url = new URL(`https://api.data.gov.in/resource/${resource}`);
  url.search = new URLSearchParams({
    "api-key": key,
    format: "json",
    limit: "100",
    "filters[commodity]": commodity,
    "filters[market]": market,
  }).toString();
  const data = await fetchJson(url);
  const candidates = (data.records ?? []).filter((r: Record<string, unknown>) =>
    r.commodity === commodity && r.market === market
  );
  // Ambiguous grades/varieties cannot safely be treated as the farmer's price.
  if (candidates.length !== 1) {
    throw new Error("Market grade needs verification");
  }
  return parseMarketRecord(candidates[0], now);
}
