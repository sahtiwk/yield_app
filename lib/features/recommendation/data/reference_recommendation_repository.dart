import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/supabase/app_failure.dart';
import '../../../shared/models/market_reference.dart';
import '../../harvest_case/domain/harvest_case.dart';
import '../domain/recommendation_snapshot.dart';

class ReferenceRecommendationRepository implements RecommendationRepository {
  ReferenceRecommendationRepository(this.prefs);
  final SharedPreferences? prefs;
  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase c) async {
    final price = hyderabadReferencePrices[c.crop.name];
    if (price == null || !c.quantityKg.isFinite || c.quantityKg <= 0) {
      throw const AppFailure('invalid_facts');
    }
    final value = price * c.quantityKg;
    final quote = <String, dynamic>{
      'reference_unit_price': price,
      'destination': {
        'id': 'bowenpally-reference',
        'name': 'Bowenpally',
        'action': 'reference_price',
        'net_value': value, 'low': value, 'high': value,
        // Route fields are not applicable and are hidden for reference quotes.
        'distance_km': 0, 'travel_hours': 0,
      },
      'alternatives': <dynamic>[],
      'observed_at': hyderabadReferenceDate.toIso8601String(),
      'assumption_codes': ['reference_notice'],
      'sources': [hyderabadPriceSource],
    };
    final result = RecommendationSnapshot.fromJson(c.id, quote);
    if (prefs != null) {
      final saved = await prefs!.setString(
        'reference_quote_${c.id}',
        jsonEncode({
          'crop_id': c.crop.id,
          'quantity_kg': c.quantityKg,
          'quote': quote,
        }),
      );
      if (!saved) throw const AppFailure('save_failed');
    }
    return result;
  }
}

class ReferenceFallbackRepository implements RecommendationRepository {
  ReferenceFallbackRepository(this.live, this.reference);
  final RecommendationRepository live, reference;
  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase c) async {
    try {
      return await live.evaluate(c);
    } catch (_) {
      return reference.evaluate(c);
    }
  }
}
