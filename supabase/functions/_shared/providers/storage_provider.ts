export interface StorageObservation {
  capacity_kg: number;
  available: boolean;
  observed_at: string;
  rate_per_kg_day: number;
  source_name: string;
}

// A directory listing is not proof of current capacity. Only dated, verified
// observations may establish viability; ingestion stays server-owned.
export function viableStorage(
  rows: StorageObservation[],
  quantity: number,
  now: number,
) {
  return rows.filter((r) =>
    r.available && r.source_name &&
    Number.isFinite(Number(r.capacity_kg)) &&
    Number(r.capacity_kg) >= quantity &&
    Number.isFinite(Number(r.rate_per_kg_day)) &&
    Number(r.rate_per_kg_day) >= 0 &&
    now >= Date.parse(r.observed_at) &&
    now - Date.parse(r.observed_at) <= 24 * 3600000
  );
}
