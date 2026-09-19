import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/harvest_case.dart';
import '../../../shared/models/crop_catalog.dart';
import 'local_harvest_case_repository.dart';

class SupabaseHarvestCaseRepository implements HarvestCaseRepository {
  SupabaseHarvestCaseRepository(this.client);
  final SupabaseClient client;
  @override
  final crops = cropCatalog;
  @override
  HarvestCase createDraft() => newHarvestDraft();
  @override
  Future<HarvestCase> confirm(HarvestCase draft) async {
    validateHarvest(draft);
    await client
        .rpc('save_harvest_case', params: {'payload': caseToJson(draft)})
        .timeout(const Duration(seconds: 20));
    return draft.copyWith(status: 'active');
  }

  @override
  Future<List<HarvestCase>> getActiveCases() async {
    final rows = await client
        .from('harvest_cases')
        .select('*,harvest_case_constraints(*)')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 20));
    return rows.map(caseFromJson).toList();
  }
}
