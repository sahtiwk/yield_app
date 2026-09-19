import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/app_failure.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../home/presentation/home_controller.dart';
import '../../domain/harvest_case.dart';
import '../../data/local_harvest_case_repository.dart';
import '../../data/supabase_harvest_case_repository.dart';
import '../../../recommendation/domain/recommendation_snapshot.dart';
import '../../../recommendation/data/supabase_recommendation_repository.dart';

final harvestRepositoryProvider = Provider<HarvestCaseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? LocalHarvestCaseRepository(ref.read(localPreferencesProvider))
      : SupabaseHarvestCaseRepository(client);
});
final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? UnavailableRecommendationRepository()
      : SupabaseRecommendationRepository(client);
});
final draftProvider = NotifierProvider<DraftController, HarvestCase>(
  DraftController.new,
);
final activeCasesProvider = FutureProvider<List<HarvestCase>>(
  (ref) => ref.watch(harvestRepositoryProvider).getActiveCases(),
);

class DraftController extends Notifier<HarvestCase> {
  @override
  HarvestCase build() => ref.read(harvestRepositoryProvider).createDraft();
  void update(HarvestCase value) => state = value;
  void reset() => state = ref.read(harvestRepositoryProvider).createDraft();
}

class CaseSession {
  const CaseSession({
    required this.harvestCase,
    this.recommendation,
    this.issue,
    this.refreshing = false,
    this.changed = false,
  });
  final HarvestCase harvestCase;
  final RecommendationSnapshot? recommendation;
  final String? issue;
  final bool refreshing, changed;
}

final sessionProvider =
    NotifierProvider<SessionController, AsyncValue<CaseSession?>>(
      SessionController.new,
    );

class SessionController extends Notifier<AsyncValue<CaseSession?>> {
  int _generation = 0;
  @override
  AsyncValue<CaseSession?> build() {
    _generation++;
    return const AsyncData(null);
  }

  Future<bool> confirm() async {
    if (state.isLoading || state.value?.refreshing == true) return false;
    final generation = ++_generation;
    final draft = ref.read(draftProvider);
    final repository = ref.read(harvestRepositoryProvider);
    state = const AsyncLoading();
    try {
      final saved = await repository.confirm(draft);
      if (!ref.mounted || generation != _generation) return false;
      ref.invalidate(activeCasesProvider);
      ref.read(draftProvider.notifier).update(saved);
      state = AsyncData(CaseSession(harvestCase: saved));
      unawaited(refresh());
      return ref.mounted;
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stack);
      }
      return false;
    }
  }

  Future<void> openCase(HarvestCase harvestCase) async {
    _generation++;
    ref.read(draftProvider.notifier).update(harvestCase);
    state = AsyncData(CaseSession(harvestCase: harvestCase));
    await refresh();
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null || current.refreshing) return;
    final generation = ++_generation;
    final repository = ref.read(recommendationRepositoryProvider);
    state = AsyncData(
      CaseSession(
        harvestCase: current.harvestCase,
        recommendation: current.recommendation,
        refreshing: true,
      ),
    );
    try {
      final result = await repository.evaluate(current.harvestCase);
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        CaseSession(
          harvestCase: current.harvestCase,
          recommendation: result,
          changed:
              current.recommendation != null &&
              (current.recommendation!.best.id != result.best.id ||
                  (current.recommendation!.best.netValue - result.best.netValue)
                          .abs() >
                      current.recommendation!.best.netValue.abs() * .05),
        ),
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        CaseSession(
          harvestCase: current.harvestCase,
          recommendation: current.recommendation,
          issue: error is AppFailure ? error.code : 'estimate_unavailable',
        ),
      );
    }
  }
}
