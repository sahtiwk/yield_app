import { CropModel, qualityRetention } from "./crop_decay.ts";

export interface Scenario {
  action?: "sell_today" | "direct_buyer";
  id: string;
  name: string;
  price_per_kg: number;
  distance_km: number;
  travel_hours: number;
  transport_cost_per_km: number;
  storage_cost: number;
  delay_hours: number;
}
export function evaluate(
  quantity: number,
  ageHours: number,
  deadlineHours: number,
  model: CropModel,
  scenarios: Scenario[],
  baselineName: string,
) {
  if (
    ![quantity, ageHours, deadlineHours].every(Number.isFinite) ||
    quantity <= 0 || ageHours < 0 || deadlineHours < 0
  ) throw new Error("Invalid harvest facts");
  const results = scenarios.filter((s) => {
    const values = [
      s.price_per_kg,
      s.distance_km,
      s.travel_hours,
      s.transport_cost_per_km,
      s.storage_cost,
      s.delay_hours,
    ];
    return values.every((v) => Number.isFinite(v) && v >= 0) &&
      s.price_per_kg > 0 &&
      s.travel_hours + s.delay_hours <= deadlineHours &&
      ageHours + s.travel_hours + s.delay_hours < model.shelf_life_hours;
  }).map((s) => {
    const quality = qualityRetention(
      model,
      ageHours + s.travel_hours + s.delay_hours,
    );
    const costs = s.distance_km * s.transport_cost_per_km + s.storage_cost;
    const gross = quantity * quality * s.price_per_kg;
    return {
      ...s,
      quality,
      net_value: Math.round((gross - costs) * 100) / 100,
      low: Math.round(gross * .9 - costs),
      high: Math.round(gross * 1.1 - costs),
    };
  }).sort((a, b) => b.net_value - a.net_value || a.id.localeCompare(b.id));
  const baseline = results.find((s) =>
    s.name.trim().toLowerCase() === baselineName.trim().toLowerCase()
  );
  return {
    results,
    baseline_value: baseline?.net_value ?? null,
    value_difference: results.length && baseline
      ? Math.round((results[0].net_value - baseline.net_value) * 100) / 100
      : null,
  };
}
