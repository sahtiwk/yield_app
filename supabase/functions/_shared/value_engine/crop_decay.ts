export interface CropModel {
  base_decay_per_hour: number;
  shelf_life_hours: number;
  source_reference: string;
  reviewed: boolean;
}

export function qualityRetention(model: CropModel, elapsedHours: number) {
  if (
    !model.reviewed || !model.source_reference ||
    !Number.isFinite(model.base_decay_per_hour) ||
    model.base_decay_per_hour < 0 || model.base_decay_per_hour > 1 ||
    !Number.isFinite(model.shelf_life_hours) ||
    model.shelf_life_hours <= 0 || !Number.isFinite(elapsedHours) ||
    elapsedHours < 0
  ) {
    throw new Error(
      "A reviewed crop model and valid elapsed time are required",
    );
  }
  if (elapsedHours >= model.shelf_life_hours) return 0;
  return Math.exp(-model.base_decay_per_hour * elapsedHours);
}
