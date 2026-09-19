import { evaluate, Scenario } from "./value_engine.ts";
import { CropModel, qualityRetention } from "./crop_decay.ts";
import { parseMarketRecord } from "../providers/market_price_provider.ts";
import { viableStorage } from "../providers/storage_provider.ts";
import { sellingDeadline } from "./deadline.ts";
import { viableBuyers } from "../providers/buyer_provider.ts";

// Synthetic parameters belong only in tests; these are not scientific defaults.
const model: CropModel = {
  reviewed: true,
  source_reference: "test fixture",
  base_decay_per_hour: .01,
  shelf_life_hours: 48,
};
const scenario: Scenario = {
  id: "a",
  name: "Village market",
  price_per_kg: 20,
  distance_km: 10,
  travel_hours: 1,
  transport_cost_per_km: 10,
  storage_cost: 0,
  delay_hours: 0,
};
function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
function throws(fn: () => unknown) {
  let threw = false;
  try {
    fn();
  } catch {
    threw = true;
  }
  assert(threw);
}

Deno.test("buyer offers require matching condition, capacity, freshness and expiry", () => {
  const now = Date.parse("2026-09-19T12:00:00Z");
  const offer = {
    id: "offer",
    destination_id: "market",
    crop_id: "tomato",
    accepted_conditions: ["Ready"],
    available: true,
    capacity_kg: 100,
    price_per_kg: 25,
    observed_at: "2026-09-19T10:00:00Z",
    valid_until: "2026-09-19T18:00:00Z",
    source_name: "test",
  };
  assert(viableBuyers([offer], 100, "Ready", now).length === 1);
  assert(viableBuyers([offer], 101, "Ready", now).length === 0);
  assert(viableBuyers([offer], 100, "Damaged", now).length === 0);
  assert(
    viableBuyers([{ ...offer, available: false }], 100, "Ready", now).length ===
      0,
  );
  assert(
    viableBuyers(
      [{ ...offer, valid_until: "2026-09-19T11:00:00Z" }],
      100,
      "Ready",
      now,
    ).length === 0,
  );
});

Deno.test("net value accounts for quantity, quality and costs", () => {
  const output = evaluate(100, 0, 12, model, [scenario], "Village market");
  assert(output.results[0].net_value === 1880.1);
  assert(output.value_difference === 0);
  assert(
    evaluate(200, 0, 12, model, [scenario], "unknown").results[0].net_value >
      output.results[0].net_value,
  );
});
Deno.test("deadline and shelf life are hard constraints", () => {
  assert(evaluate(100, 0, .5, model, [scenario], "").results.length === 0);
  assert(evaluate(100, 48, 12, model, [scenario], "").results.length === 0);
});
Deno.test("unknown baseline never manufactures an advantage", () => {
  const result = evaluate(100, 0, 12, model, [scenario], "usual buyer");
  assert(result.baseline_value === null && result.value_difference === null);
});
Deno.test("reject unreviewed and nonfinite inputs", () => {
  throws(() => qualityRetention({ ...model, reviewed: false }, 2));
  throws(() => qualityRetention(model, -1));
  throws(() => evaluate(NaN, 0, 12, model, [scenario], ""));
  assert(
    evaluate(100, 0, 12, model, [{ ...scenario, price_per_kg: Infinity }], "")
      .results.length === 0,
  );
});
Deno.test("decay is bounded and decreases with elapsed time", () => {
  assert(qualityRetention(model, 0) === 1);
  assert(qualityRetention(model, 10) < qualityRetention(model, 1));
  assert(qualityRetention(model, 48) === 0);
});
Deno.test("stable ranking and negative returns remain visible", () => {
  const b = { ...scenario, id: "b", name: "Other market" };
  assert(evaluate(100, 0, 12, model, [b, scenario], "").results[0].id === "a");
  assert(evaluate(1, 0, 12, model, [scenario], "").results[0].net_value < 0);
});
Deno.test("market units convert and stale or invalid dates fail", () => {
  const now = Date.parse("2026-09-19T12:00:00Z");
  assert(
    parseMarketRecord({ modal_price: "2500", arrival_date: "19/09/2026" }, now)
      .price_per_kg === 25,
  );
  throws(() =>
    parseMarketRecord({ modal_price: "2500", arrival_date: "31/09/2026" }, now)
  );
  throws(() =>
    parseMarketRecord({ modal_price: "2500", arrival_date: "01/09/2026" }, now)
  );
});
Deno.test("storage requires capacity, freshness and availability", () => {
  const now = Date.parse("2026-09-19T12:00:00Z");
  const row = {
    capacity_kg: 100,
    available: true,
    observed_at: "2026-09-19T10:00:00Z",
    rate_per_kg_day: 1,
    source_name: "test",
  };
  assert(viableStorage([row], 100, now).length === 1);
  assert(viableStorage([{ ...row, available: false }], 100, now).length === 0);
  assert(viableStorage([row], 101, now).length === 0);
});
Deno.test("hard same-day constraint wins over a later urgency and retries do not extend it", () => {
  const deadline = sellingDeadline("2026-09-19T05:00:00Z", "Within 3 days", [
    { is_hard: true, constraint_type: "same_day_sale_required", value: "true" },
  ]);
  assert(deadline === Date.parse("2026-09-19T18:30:00Z"));
  throws(() =>
    sellingDeadline("2026-09-19T05:00:00Z", "Within 3 days", [
      { is_hard: true, constraint_type: "must_sell_by", value: "unknown" },
    ])
  );
});
