import '../../../shared/models/crop.dart';
import '../../harvest_case/domain/harvest_case.dart';

class RecommendationAlternative {
  const RecommendationAlternative({
    required this.action,
    required this.destination,
    required this.value,
    required this.status,
    required this.reason,
  });
  final String action, destination, value, status, reason;
}

class RecommendationSnapshot {
  const RecommendationSnapshot({
    required this.caseId,
    required this.action,
    required this.destination,
    required this.expectedNetValue,
    required this.range,
    required this.baselineValue,
    required this.valueDifference,
    required this.reasons,
    required this.assumptions,
    required this.dataFreshness,
    required this.alternatives,
    required this.temperature,
    required this.humidity,
    required this.remainingWindow,
    required this.marketRates,
  });
  final String caseId, action;
  final Destination destination;
  final String expectedNetValue, range, baselineValue, valueDifference;
  final List<({String title, String detail})> reasons;
  final List<String> assumptions;
  final String dataFreshness, temperature, humidity, remainingWindow;
  final List<RecommendationAlternative> alternatives;
  final List<({String name, String price})> marketRates;
}

abstract interface class RecommendationRepository {
  Future<RecommendationSnapshot> evaluate(HarvestCase harvestCase);
  Future<RecommendationSnapshot> simulateChange(HarvestCase harvestCase);
}
