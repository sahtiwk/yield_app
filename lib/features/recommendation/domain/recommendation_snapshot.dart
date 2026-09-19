import '../../harvest_case/domain/harvest_case.dart';

class ScenarioResult {
  const ScenarioResult({
    required this.id,
    required this.name,
    required this.action,
    required this.netValue,
    required this.low,
    required this.high,
    required this.distanceKm,
    required this.travelHours,
  });
  final String id, name, action;
  final double netValue, low, high, distanceKm, travelHours;
  factory ScenarioResult.fromJson(Map<String, dynamic> d) => ScenarioResult(
    id: d['id'] as String,
    name: d['name'] as String,
    action: d['action'] as String? ?? 'sell_today',
    netValue: _number(d['net_value']),
    low: _number(d['low']),
    high: _number(d['high']),
    distanceKm: _number(d['distance_km']),
    travelHours: _number(d['travel_hours']),
  );
}

double _number(dynamic value) {
  if (value is! num || !value.isFinite) {
    throw const FormatException('Invalid estimate');
  }
  return value.toDouble();
}

class RecommendationSnapshot {
  const RecommendationSnapshot({
    required this.caseId,
    required this.best,
    required this.alternatives,
    required this.observedAt,
    required this.assumptionCodes,
    required this.sources,
    this.baselineValue,
    this.valueDifference,
    this.temperature,
    this.humidity,
    this.referenceUnitPrice,
  });
  final String caseId;
  final ScenarioResult best;
  final List<ScenarioResult> alternatives;
  final double? baselineValue, valueDifference, temperature, humidity;
  final double? referenceUnitPrice;
  bool get isReference => referenceUnitPrice != null;
  final DateTime observedAt;
  final List<String> assumptionCodes, sources;
  factory RecommendationSnapshot.fromJson(String id, Map<String, dynamic> d) =>
      RecommendationSnapshot(
        caseId: id,
        referenceUnitPrice: d['reference_unit_price'] == null
            ? null
            : _number(d['reference_unit_price']),
        best: ScenarioResult.fromJson(
          Map<String, dynamic>.from(d['destination'] as Map),
        ),
        alternatives: [
          for (final row in d['alternatives'] as List)
            ScenarioResult.fromJson(Map<String, dynamic>.from(row as Map)),
        ],
        observedAt: DateTime.parse(d['observed_at'] as String),
        assumptionCodes: List<String>.from(d['assumption_codes'] as List),
        sources: List<String>.from(d['sources'] as List),
        baselineValue: d['baseline_value'] == null
            ? null
            : _number(d['baseline_value']),
        valueDifference: d['value_difference'] == null
            ? null
            : _number(d['value_difference']),
        temperature: d['temperature_c'] == null
            ? null
            : _number(d['temperature_c']),
        humidity: d['humidity_percent'] == null
            ? null
            : _number(d['humidity_percent']),
      );
}

abstract interface class RecommendationRepository {
  Future<RecommendationSnapshot> evaluate(HarvestCase harvestCase);
}
