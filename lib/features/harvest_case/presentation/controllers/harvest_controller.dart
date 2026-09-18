import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/harvest_case.dart';
import '../../data/mock_harvest_case_repository.dart';
import '../../../recommendation/domain/recommendation_snapshot.dart';
import '../../../recommendation/data/mock_recommendation_repository.dart';

final harvestRepositoryProvider = Provider<HarvestCaseRepository>(
  (ref) => MockHarvestCaseRepository(),
);
final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (ref) => MockRecommendationRepository(),
);
final draftProvider = NotifierProvider<DraftController, HarvestCase>(
  DraftController.new,
);

final activeCasesProvider = FutureProvider<List<HarvestCase>>((ref) {
  return ref.read(harvestRepositoryProvider).getActiveCases();
});

class DraftController extends Notifier<HarvestCase> {
  @override
  HarvestCase build() => ref.read(harvestRepositoryProvider).createDraft();
  void update(HarvestCase value) => state = value;
  void reset() => state = ref.read(harvestRepositoryProvider).createDraft();
}

class CaseSession {
  const CaseSession({
    required this.harvestCase,
    required this.recommendation,
    this.changed = false,
    this.decision,
  });
  final HarvestCase harvestCase;
  final RecommendationSnapshot recommendation;
  final bool changed;
  final String? decision;
}

final sessionProvider =
    NotifierProvider<SessionController, AsyncValue<CaseSession?>>(
      SessionController.new,
    );

class SessionController extends Notifier<AsyncValue<CaseSession?>> {
  CaseSession? _last;
  @override
  AsyncValue<CaseSession?> build() => const AsyncData(null);
  Future<bool> confirm() async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final c = await ref
          .read(harvestRepositoryProvider)
          .confirm(ref.read(draftProvider));
      final r = await ref.read(recommendationRepositoryProvider).evaluate(c);
      return _last = CaseSession(harvestCase: c, recommendation: r);
    });
    return !state.hasError;
  }

  Future<void> simulate() async {
    final current = _last;
    if (current == null || state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final r = await ref
          .read(recommendationRepositoryProvider)
          .simulateChange(current.harvestCase);
      return _last = CaseSession(
        harvestCase: current.harvestCase,
        recommendation: r,
        changed: true,
      );
    });
  }

  void decide(String decision) {
    final s = _last;
    if (s == null) return;
    _last = CaseSession(
      harvestCase: s.harvestCase,
      recommendation: s.recommendation,
      changed: s.changed,
      decision: decision,
    );
    state = AsyncData(_last);
  }
}
