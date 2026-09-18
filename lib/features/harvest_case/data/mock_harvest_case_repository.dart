import '../domain/harvest_case.dart';
import '../../../shared/models/crop.dart';

class MockHarvestCaseRepository implements HarvestCaseRepository {
  final List<HarvestCase> _activeCases = [];

  @override
  final crops = const [
    Crop(id: 'tomato', name: 'Tomato', variety: 'Hybrid red'),
    Crop(id: 'okra', name: 'Okra', variety: 'Fresh green'),
    Crop(id: 'brinjal', name: 'Brinjal', variety: 'Purple long'),
  ];
  @override
  HarvestCase createDraft() => HarvestCase(
    id: 'HT-${DateTime.now().millisecondsSinceEpoch % 10000}',
    crop: crops.first,
    quantityKg: 650,
    location: '',
    harvestStatus: 'Harvested',
    harvestedAt: DateTime.now(),
    urgency: 'Must sell today',
    farmerCondition: 'Ready',
    currentPlan: '',
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
    final confirmed = draft.copyWith(status: 'active');
    final index = _activeCases.indexWhere((c) => c.id == confirmed.id);
    if (index >= 0) {
      _activeCases[index] = confirmed;
    } else {
      _activeCases.add(confirmed);
    }
    return confirmed;
  }

  @override
  Future<List<HarvestCase>> getActiveCases() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_activeCases);
  }
}
