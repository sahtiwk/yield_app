export interface BuyerObservation {
  id: string;
  destination_id: string;
  crop_id: string;
  accepted_conditions: string[];
  available: boolean;
  valid_until: string;
  capacity_kg: number;
  price_per_kg: number;
  observed_at: string;
  source_name: string;
}

export function viableBuyers(
  rows: BuyerObservation[],
  quantity: number,
  grade: string,
  now: number,
) {
  return rows.filter((r) =>
    r.available && r.source_name && Array.isArray(r.accepted_conditions) &&
    r.accepted_conditions.includes(grade) && Date.parse(r.valid_until) > now &&
    Number.isFinite(Number(r.capacity_kg)) &&
    Number(r.capacity_kg) >= quantity &&
    Number.isFinite(Number(r.price_per_kg)) &&
    Number(r.price_per_kg) > 0 &&
    now >= Date.parse(r.observed_at) &&
    now - Date.parse(r.observed_at) <= 24 * 3600000 // 24-hour freshness
  );
}
