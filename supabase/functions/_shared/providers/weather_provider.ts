import { fetchJson, finite } from "./http.ts";

export async function weather(latitude: number, longitude: number) {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.search = new URLSearchParams({
    latitude: String(latitude),
    longitude: String(longitude),
    current: "temperature_2m,relative_humidity_2m",
    timezone: "UTC",
  }).toString();
  const data = await fetchJson(url);
  const current = data.current;
  const temperature = finite(current?.temperature_2m);
  const humidity = finite(current?.relative_humidity_2m);
  if (temperature < -60 || temperature > 65 || humidity < 0 || humidity > 100) {
    throw new Error("Invalid weather observation");
  }
  return {
    temperature_c: temperature,
    humidity_percent: humidity,
    observed_at: `${current.time}Z`,
    source_name: "Open-Meteo",
    source_type: "live",
  };
}
