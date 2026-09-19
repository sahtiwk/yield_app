import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/harvest_case.dart';
import '../../../shared/models/crop_catalog.dart';
import '../../../core/supabase/app_failure.dart';

class LocalHarvestCaseRepository implements HarvestCaseRepository {
  LocalHarvestCaseRepository(this.preferences);
  final SharedPreferences? preferences;
  final Map<String, HarvestCase> _memory = {};
  @override
  final crops = cropCatalog;
  @override
  HarvestCase createDraft() => newHarvestDraft();
  @override
  Future<HarvestCase> confirm(HarvestCase draft) async {
    validateHarvest(draft);
    final cases = await getActiveCases();
    final confirmed = draft.copyWith(status: 'active');
    final updated = {for (final c in cases) c.id: c, confirmed.id: confirmed};
    if (preferences != null) {
      final saved = await preferences!.setString(
        'harvest_cases_v1',
        jsonEncode(updated.values.map(caseToJson).toList()),
      );
      if (!saved) throw const AppFailure('save_failed');
    }
    _memory
      ..clear()
      ..addAll(updated);
    return confirmed;
  }

  @override
  Future<List<HarvestCase>> getActiveCases() async {
    final raw = preferences?.getString('harvest_cases_v1');
    if (raw == null) return _memory.values.toList().reversed.toList();
    try {
      return (jsonDecode(raw) as List)
          .map((row) => caseFromJson(Map<String, dynamic>.from(row as Map)))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      throw const AppFailure('local_data_error');
    }
  }
}

HarvestCase newHarvestDraft() {
  final random = Random.secure();
  return HarvestCase(
    id: List.generate(24, (_) => random.nextInt(16).toRadixString(16)).join(),
    crop: cropCatalog.first,
    quantityKg: 0,
    location: '',
    harvestStatus: 'Harvested',
    harvestedAt: DateTime.now(),
    urgency: 'Must sell today',
    farmerCondition: 'Ready',
    currentPlan: '',
    constraints: const [
      HarvestConstraint(type: 'must_sell_by', value: 'Must sell today'),
    ],
  );
}

void validateHarvest(HarvestCase c) {
  if (!c.quantityKg.isFinite ||
      c.quantityKg <= 0 ||
      c.quantityKg > 100000 ||
      c.location.trim().isEmpty ||
      c.location.length > 120 ||
      c.currentPlan.length > 100 ||
      (c.latitude == null) != (c.longitude == null) ||
      (c.latitude != null &&
          (!c.latitude!.isFinite ||
              c.latitude!.abs() > 90 ||
              !c.longitude!.isFinite ||
              c.longitude!.abs() > 180))) {
    throw const AppFailure('invalid_facts');
  }
}

Map<String, dynamic> caseToJson(HarvestCase c) => {
  'id': c.id,
  'crop_id': c.crop.id,
  'variety': c.crop.variety,
  'quantity_kg': c.quantityKg,
  'location_label': c.location,
  'latitude': c.latitude,
  'longitude': c.longitude,
  'harvest_status': c.harvestStatus,
  'harvested_at': c.harvestedAt.toUtc().toIso8601String(),
  'urgency': c.urgency,
  'farmer_condition': c.farmerCondition,
  'current_plan': c.currentPlan,
  'status': c.status,
  'constraints': [
    for (final x in c.constraints)
      {'type': x.type, 'value': x.value, 'is_hard': x.isHard},
  ],
};
HarvestCase caseFromJson(Map<String, dynamic> r) => HarvestCase(
  id: r['id'] as String,
  crop: cropCatalog
      .firstWhere((c) => c.id == r['crop_id'])
      .withVariety(r['variety'] as String? ?? ''),
  quantityKg: (r['quantity_kg'] as num).toDouble(),
  location: r['location_label'] as String,
  latitude: (r['latitude'] as num?)?.toDouble(),
  longitude: (r['longitude'] as num?)?.toDouble(),
  harvestStatus: r['harvest_status'] as String,
  harvestedAt: DateTime.parse(r['harvested_at'] as String).toLocal(),
  urgency: r['urgency'] as String,
  farmerCondition: r['farmer_condition'] as String,
  currentPlan: r['current_plan'] as String,
  status: r['status'] as String? ?? 'active',
  constraints: [
    for (final x
        in (r['constraints'] ?? r['harvest_case_constraints'] ?? []) as List)
      HarvestConstraint(
        type: (x['type'] ?? x['constraint_type']) as String,
        value: x['value'] as String,
        isHard: x['is_hard'] as bool? ?? true,
      ),
  ],
);
