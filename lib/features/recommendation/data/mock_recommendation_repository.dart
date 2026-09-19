import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../harvest_case/domain/harvest_case.dart';
import '../domain/recommendation_snapshot.dart';

class MockRecommendationRepository implements RecommendationRepository {
  MockRecommendationRepository(this.prefs);
  final SharedPreferences? prefs;

  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase harvestCase) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final cacheKey = 'mock_rec_${harvestCase.id}';

    // For realism, we generate a slightly varied mock based on the case quantity
    final basePrice = 25.0; // ₹25/kg
    final qty = harvestCase.quantityKg;
    final totalValue = basePrice * qty;

    final mockData = {
      'destination': {
        'id': 'mock-best',
        'name': 'WayCool Foods (Direct)',
        'action': 'direct_buyer',
        'net_value': totalValue,
        'low': totalValue * 0.9,
        'high': totalValue * 1.1,
        'distance_km': 15.5,
        'travel_hours': 0.5,
      },
      'alternatives': [
        {
          'id': 'mock-alt-1',
          'name': 'Bowenpally',
          'action': 'sell_today',
          'net_value': totalValue * 0.85,
          'low': totalValue * 0.75,
          'high': totalValue * 0.95,
          'distance_km': 22.0,
          'travel_hours': 1.2,
        },
        {
          'id': 'mock-alt-2',
          'name': 'Local Mandi (Store 1 day)',
          'action': 'sell_today',
          'net_value': totalValue * 0.80,
          'low': totalValue * 0.70,
          'high': totalValue * 0.90,
          'distance_km': 5.0,
          'travel_hours': 0.2,
        },
      ],
      'observed_at': DateTime.now().toIso8601String(),
      'assumption_codes': [
        'estimate_caution',
        'reference_decay',
        'sensitivity_range',
      ],
      'sources': ['WayCool Daily Procurement Rate', 'Open-Meteo Weather Data'],
      'baseline_value': totalValue * 0.82,
      'value_difference': totalValue * 0.18,
      'temperature_c': 28.5,
      'humidity_percent': 65.0,
    };

    // Store the mock data
    await prefs?.setString(cacheKey, jsonEncode(mockData));

    return RecommendationSnapshot.fromJson(harvestCase.id, mockData);
  }
}
