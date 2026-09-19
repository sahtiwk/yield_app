import { fetchJson, finite } from "./http.ts";

export async function distance(
  from: [number, number],
  to: [number, number],
  key: string | undefined,
) {
  if (!key) throw new Error("Routing provider is not configured");
  const data = await fetchJson(
    "https://api.openrouteservice.org/v2/directions/driving-car",
    {
      method: "POST",
      headers: { Authorization: key, "Content-Type": "application/json" },
      body: JSON.stringify({ coordinates: [from, to] }),
    },
  );
  const summary = data.routes?.[0]?.summary;
  const km = finite(summary?.distance) / 1000;
  const hours = finite(summary?.duration) / 3600;
  if (km < 0 || hours < 0) throw new Error("Invalid route");
  return {
    distance_km: km,
    travel_hours: hours,
    source_name: "openrouteservice",
  };
}
