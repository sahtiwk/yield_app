import '../../../shared/models/crop.dart';

class HarvestConstraint {
  const HarvestConstraint({
    required this.type,
    required this.value,
    this.isHard = true,
    this.source = 'farmer',
  });
  final String type;
  final String value;
  final bool isHard;
  final String source;
}

class HarvestCase {
  const HarvestCase({
    required this.id,
    required this.crop,
    required this.quantityKg,
    required this.location,
    required this.harvestStatus,
    required this.harvestedAt,
    required this.urgency,
    required this.farmerCondition,
    required this.currentPlan,
    required this.constraints,
    this.status = 'draft',
  });
  final String id;
  final Crop crop;
  final double quantityKg;
  final String location;
  final String harvestStatus;
  final DateTime harvestedAt;
  final String urgency;
  final String farmerCondition;
  final String currentPlan;
  final List<HarvestConstraint> constraints;
  final String status;

  HarvestCase copyWith({
    Crop? crop,
    double? quantityKg,
    String? location,
    String? harvestStatus,
    DateTime? harvestedAt,
    String? urgency,
    String? farmerCondition,
    String? currentPlan,
    String? status,
  }) => HarvestCase(
    id: id,
    crop: crop ?? this.crop,
    quantityKg: quantityKg ?? this.quantityKg,
    location: location ?? this.location,
    harvestStatus: harvestStatus ?? this.harvestStatus,
    harvestedAt: harvestedAt ?? this.harvestedAt,
    urgency: urgency ?? this.urgency,
    farmerCondition: farmerCondition ?? this.farmerCondition,
    currentPlan: currentPlan ?? this.currentPlan,
    constraints: urgency == null
        ? constraints
        : [HarvestConstraint(type: 'must_sell_by', value: urgency)],
    status: status ?? this.status,
  );
}

abstract interface class HarvestCaseRepository {
  HarvestCase createDraft();
  List<Crop> get crops;
  Future<HarvestCase> confirm(HarvestCase draft);
  Future<List<HarvestCase>> getActiveCases();
}
