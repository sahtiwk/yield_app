export async function fetchJson(url: string | URL, init: RequestInit = {}) {
  const response = await fetch(url, {
    ...init,
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) {
    throw new Error(`Provider returned HTTP ${response.status}`);
  }
  return response.json();
}
export function finite(value: unknown): number {
  if (value == null || value === "" || typeof value === "boolean") {
    throw new Error("Missing numeric value");
  }
  const number = Number(value);
  if (!Number.isFinite(number)) throw new Error("Invalid numeric value");
  return number;
}
