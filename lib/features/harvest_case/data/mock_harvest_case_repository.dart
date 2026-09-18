import '../domain/harvest_case.dart';
import '../../../shared/models/crop.dart';

class MockHarvestCaseRepository implements HarvestCaseRepository {
  @override
  final crops = const [
    Crop(id: 'tomato', name: 'Tomato', variety: 'Hybrid red'),
    Crop(id: 'okra', name: 'Okra', variety: 'Fresh green'),
    Crop(id: 'brinjal', name: 'Brinjal', variety: 'Purple long'),
  ];
  @override
  HarvestCase createDraft() => HarvestCase(
    id: 'HT-2048',
    crop: crops.first,
    quantityKg: 650,
    location: 'Kurnool, Andhra Pradesh',
    harvestStatus: 'Harvested',
    harvestedAt: DateTime(2026, 9, 18, 7, 15),
    urgency: 'Must sell today',
    farmerCondition: 'Ripe',
    currentPlan: 'Village mandi',
    constraints: const [
      HarvestConstraint(type: 'same_day_sale_required', value: 'true'),
    ],
  );
  @override
  Future<HarvestCase> confirm(HarvestCase draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!draft.quantityKg.isFinite ||
        draft.quantityKg <= 0 ||
        draft.quantityKg > 100000 ||
        draft.location.trim().isEmpty ||
        draft.currentPlan.trim().isEmpty) {
      throw const FormatException(
        'Please check the weight, location and current plan.',
      );
    }
    return draft.copyWith(status: 'active');
  }
}
