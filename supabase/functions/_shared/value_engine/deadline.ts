const dayCounts: Record<string, number> = {
  "Must sell today": 1,
  "Within 2 days": 2,
  "Within 3 days": 3,
};
export function sellingDeadline(
  createdAt: string,
  urgency: string,
  constraints: { is_hard: boolean; constraint_type: string; value: string }[],
) {
  let days = dayCounts[urgency];
  if (!days) throw new Error("Unknown selling deadline");
  for (const c of constraints) {
    if (!c.is_hard) continue;
    if (c.constraint_type === "must_sell_by" && dayCounts[c.value]) {
      days = Math.min(days, dayCounts[c.value]);
    } else if (
      c.constraint_type === "same_day_sale_required" && c.value === "true"
    ) days = 1;
    else if (
      c.constraint_type === "same_day_sale_required" && c.value === "false"
    ) continue;
    else throw new Error("Unmodeled hard constraint");
  }
  const created = new Date(Date.parse(createdAt) + 5.5 * 3600000);
  if (!Number.isFinite(created.getTime())) {
    throw new Error("Invalid registration date");
  }
  return Date.UTC(
    created.getUTCFullYear(),
    created.getUTCMonth(),
    created.getUTCDate() + days,
  ) - 5.5 * 3600000;
}
