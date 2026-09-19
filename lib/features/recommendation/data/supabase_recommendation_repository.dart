import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/app_failure.dart';
import '../../harvest_case/domain/harvest_case.dart';
import '../domain/recommendation_snapshot.dart';

class SupabaseRecommendationRepository implements RecommendationRepository {
  SupabaseRecommendationRepository(this.client);
  final SupabaseClient client;
  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase harvestCase) async {
    try {
      final response = await client.functions
          .invoke('context_orchestrator', body: {'case_id': harvestCase.id})
          .timeout(const Duration(seconds: 35));
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['status'] != 'ready') {
        throw AppFailure(data['code'] as String? ?? 'estimate_unavailable');
      }
      return RecommendationSnapshot.fromJson(harvestCase.id, data);
    } on FunctionException catch (error) {
      throw AppFailure(
        error.status == 401 ? 'sign_in_required' : 'estimate_unavailable',
      );
    }
  }
}

class UnavailableRecommendationRepository implements RecommendationRepository {
  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase harvestCase) async =>
      throw const AppFailure('connection_required');
}
