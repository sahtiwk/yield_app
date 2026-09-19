import { createClient } from "@supabase/supabase-js";
import { weather } from "../_shared/providers/weather_provider.ts";
import { distance } from "../_shared/providers/distance_provider.ts";
import { marketPrice } from "../_shared/providers/market_price_provider.ts";
import { viableBuyers } from "../_shared/providers/buyer_provider.ts";
import { evaluate, Scenario } from "../_shared/value_engine/value_engine.ts";
import { sellingDeadline } from "../_shared/value_engine/deadline.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
const unavailable = (code: string) => reply({ status: "unavailable", code });

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (request.method !== "POST") {
    return reply({ code: "method_not_allowed" }, 405);
  }
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return reply({ code: "sign_in_required" }, 401);
  }
  try {
    const client = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: { headers: { Authorization: authorization } },
        auth: { persistSession: false },
      },
    );
    // Verify with Auth; all database reads retain the caller's RLS identity.
    const { data: identity, error: authError } = await client.auth.getUser();
    if (authError || !identity.user) {
      return reply({ code: "sign_in_required" }, 401);
    }
    let caseId: unknown;
    try {
      caseId = (await request.json()).case_id;
    } catch {
      return reply({ code: "invalid_request" }, 400);
    }
    if (typeof caseId !== "string" || !caseId || caseId.length > 100) {
      return reply({ code: "invalid_request" }, 400);
    }
    const { data: c, error } = await client.from("harvest_cases").select(
      "*,crop_configs(*),harvest_case_constraints(*)",
    ).eq("id", caseId).single();
    if (error || !c) return reply({ code: "case_not_found" }, 404);
    if (c.status !== "active") return unavailable("case_inactive");
    if (c.latitude == null || c.longitude == null) {
      return unavailable("coordinates_required");
    }
    if (c.harvest_status !== "Harvested") {
      return unavailable("harvest_time_required");
    }
    if (c.farmer_condition !== "Ready") {
      return unavailable("condition_model_required");
    }
    if (!c.crop_configs?.reviewed || c.crop_configs.is_placeholder) {
      return unavailable("crop_model_required");
    }
    const now = Date.now();
    const ageHours = (now - Date.parse(c.harvested_at)) / 3600000;
    if (!Number.isFinite(ageHours) || ageHours < 0) {
      return unavailable("future_harvest");
    }
    let deadline: number;
    try {
      deadline = sellingDeadline(
        c.created_at,
        c.urgency,
        c.harvest_case_constraints,
      );
    } catch {
      return unavailable("constraints_review");
    }
    if (deadline <= now) return unavailable("deadline_passed");
    const [weatherResult, priceResult, buyerResult] = await Promise.allSettled([
      weather(c.latitude, c.longitude),
      client.from("market_price_observations").select("*").eq(
        "crop_id",
        c.crop_id,
      )
        .gte("observed_for", new Date(now - 48 * 3600000).toISOString()).lte(
          "observed_for",
          new Date(now).toISOString(),
        )
        .neq("source_type", "seed").order("observed_for", { ascending: false })
        .limit(100),
      client.from("buyer_options").select("*").eq("crop_id", c.crop_id),
    ]);
    let weatherData;
    if (weatherResult.status === "fulfilled") weatherData = weatherResult.value;
    else {
      const { data } = await client.from("weather_observations").select("*").eq(
        "harvest_case_id",
        c.id,
      )
        .gte("observed_at", new Date(now - 3600000).toISOString()).lte(
          "observed_at",
          new Date(now).toISOString(),
        )
        .order("observed_at", { ascending: false }).limit(1);
      weatherData = data?.[0];
    }
    if (!weatherData) return unavailable("weather_unavailable");
    const cached =
      priceResult.status === "fulfilled" && !priceResult.value.error
        ? priceResult.value.data ?? []
        : [];
    const buyers =
      buyerResult.status === "fulfilled" && !buyerResult.value.error
        ? viableBuyers(
          buyerResult.value.data ?? [],
          Number(c.quantity_kg),
          c.farmer_condition,
          now,
        )
        : [];
    const { data: destinations, error: destinationError } = await client.from(
      "destinations",
    ).select("*").order("id").limit(20);
    if (destinationError) return unavailable("destinations_unavailable");
    const scenarios: Scenario[] = [];
    const sources = new Set<string>([
      weatherData.source_name,
      c.crop_configs.source_reference,
    ]);
    // Each route requires a dated price or a current buyer offer. Limit external calls.
    const eligible = (destinations ?? []).filter((d) =>
      d.transport_cost_per_km != null &&
      (cached.some((p) => p.destination_id === d.id) || buyers.some((b) =>
        b.destination_id === d.id
      ) || d.market_code)
    ).slice(0, 5);
    await Promise.all(eligible.map(async (d) => {
      let observation = cached.find((p) => p.destination_id === d.id);
      if (!observation && d.market_code) {
        try {
          observation = await marketPrice(
            c.crop_configs.name,
            d.market_code,
            Deno.env.get("DATA_GOV_API_KEY"),
            Deno.env.get("AGMARKNET_RESOURCE_ID"),
            now,
          );
        } catch {
          /* A current buyer offer can still make this destination feasible. */
        }
      }
      const offers = buyers.filter((b) => b.destination_id === d.id);
      if (!observation && !offers.length) return;
      try {
        const route = await distance([c.longitude, c.latitude], [
          d.longitude,
          d.latitude,
        ], Deno.env.get("ORS_API_KEY"));
        const common = {
          name: d.name,
          ...route,
          transport_cost_per_km: Number(d.transport_cost_per_km),
          storage_cost: 0,
          delay_hours: 0,
        };
        if (observation) {
          scenarios.push({
            ...common,
            id: d.id,
            action: "sell_today",
            price_per_kg: Number(observation.price_per_kg),
          });
          sources.add(observation.source_name);
        }
        for (const buyer of offers) {
          // Offer must still be valid on arrival, not merely at request time.
          if (
            Date.parse(buyer.valid_until) < now + route.travel_hours * 3600000
          ) continue;
          scenarios.push({
            ...common,
            id: buyer.id,
            action: "direct_buyer",
            price_per_kg: Number(buyer.price_per_kg),
          });
          sources.add(buyer.source_name);
        }
        sources.add(route.source_name);
      } catch { /* A failed routing request cannot establish feasibility. */ }
    }));
    // Free-text plans cannot identify a direct buyer unambiguously. Never substitute a
    // buyer's price for the farmer's stated market baseline.
    const marketBaseline = scenarios.find((s) =>
      s.action === "sell_today" &&
      s.name.trim().toLowerCase() === c.current_plan.trim().toLowerCase()
    );
    const evaluated = evaluate(
      Number(c.quantity_kg),
      ageHours,
      (deadline - now) / 3600000,
      c.crop_configs,
      scenarios,
      marketBaseline?.name ?? "",
    );
    if (!evaluated.results.length) return unavailable("no_feasible_options");
    const baseline = evaluated.results.find((s) => s.id === marketBaseline?.id);
    const best = evaluated.results[0];
    return reply({
      status: "ready",
      destination: best,
      alternatives: evaluated.results.slice(1, 4),
      baseline_value: baseline?.net_value ?? null,
      value_difference: baseline ? best.net_value - baseline.net_value : null,
      observed_at: new Date(now).toISOString(),
      temperature_c: weatherData.temperature_c,
      humidity_percent: weatherData.humidity_percent,
      assumption_codes: [
        "estimate_caution",
        "reference_decay",
        "sensitivity_range",
        "storage_not_ranked",
        ...(!baseline ? ["baseline_unmatched"] : []),
        ...(best.net_value < 0 ? ["negative_return"] : []),
      ],
      sources: [...sources].filter(Boolean).sort(),
    });
  } catch {
    return reply({ code: "estimate_unavailable" }, 503);
  }
});
