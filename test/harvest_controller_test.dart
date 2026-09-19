import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yield_app/core/supabase/app_failure.dart';
import 'package:yield_app/features/harvest_case/data/local_harvest_case_repository.dart';
import 'package:yield_app/features/harvest_case/domain/harvest_case.dart';
import 'package:yield_app/features/harvest_case/presentation/controllers/harvest_controller.dart';
import 'package:yield_app/features/recommendation/domain/recommendation_snapshot.dart';

class PendingRecommendationRepository implements RecommendationRepository {
  final pending = Completer<RecommendationSnapshot>();
  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase c) => pending.future;
}

class PendingHarvestRepository extends LocalHarvestCaseRepository {
  PendingHarvestRepository() : super(null);
  final pending = Completer<HarvestCase>();
  @override
  Future<HarvestCase> confirm(HarvestCase draft) => pending.future;
}

void main() {
  test(
    'Confirmation completes before a slow recommendation and accepts no plan',
    () async {
      final recommendations = PendingRecommendationRepository();
      final container = ProviderContainer(
        overrides: [
          recommendationRepositoryProvider.overrideWithValue(recommendations),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(draftProvider.notifier)
          .update(
            container
                .read(draftProvider)
                .copyWith(quantityKg: 100, location: '13.55, 78.5'),
          );
      expect(
        await container
            .read(sessionProvider.notifier)
            .confirm()
            .timeout(const Duration(seconds: 1)),
        true,
      );
      expect(container.read(sessionProvider).requireValue!.refreshing, true);
      recommendations.pending.completeError(
        const AppFailure('estimate_unavailable'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sessionProvider).requireValue!.issue, isNull);
      expect(
        container
            .read(sessionProvider)
            .requireValue!
            .recommendation!
            .isReference,
        true,
      );
    },
  );
  test('Account change ignores a pending save', () async {
    final repo = PendingHarvestRepository();
    final container = ProviderContainer(
      overrides: [harvestRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final draft = container.read(draftProvider);
    final pending = container.read(sessionProvider.notifier).confirm();
    container.invalidate(sessionProvider);
    expect(container.read(sessionProvider).requireValue, isNull);
    repo.pending.complete(draft);
    expect(await pending, false);
    expect(container.read(sessionProvider).requireValue, isNull);
  });
  test('Invalid weights are rejected at the repository boundary', () async {
    final repo = LocalHarvestCaseRepository(null);
    for (final weight in [0.0, -1.0, double.nan, double.infinity]) {
      await expectLater(
        repo.confirm(repo.createDraft().copyWith(quantityKg: weight)),
        throwsA(isA<AppFailure>()),
      );
    }
  });
  test(
    'Saved cases survive a repository restart with exact farmer facts',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repo = LocalHarvestCaseRepository(preferences);
      expect(await repo.getActiveCases(), isEmpty);
      final draft = repo.createDraft().copyWith(
        quantityKg: 125.5,
        location: 'Farm location',
        currentPlan: 'Current buyer',
        farmerCondition: 'Very ripe',
      );
      await repo.confirm(draft);
      final rows = await LocalHarvestCaseRepository(
        preferences,
      ).getActiveCases();
      expect(rows.single.quantityKg, 125.5);
      expect(rows.single.farmerCondition, 'Very ripe');
      expect(rows.single.crop.variety, draft.crop.variety);
    },
  );
  test(
    'Offline harvest uses a dated reference without inventing net returns',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(draftProvider.notifier)
          .update(
            container
                .read(draftProvider)
                .copyWith(
                  quantityKg: 940,
                  location: 'Village',
                  currentPlan: 'Market',
                ),
          );
      expect(await container.read(sessionProvider.notifier).confirm(), true);
      await Future<void>.delayed(Duration.zero);
      final session = container.read(sessionProvider).requireValue!;
      expect(session.harvestCase.quantityKg, 940);
      expect(session.recommendation!.isReference, true);
      expect(session.recommendation!.referenceUnitPrice, 10);
      expect(session.recommendation!.best.netValue, 9400);
      expect(session.recommendation!.baselineValue, isNull);
      expect(session.recommendation!.temperature, isNull);
      expect(session.issue, isNull);
      expect(
        (await container.read(activeCasesProvider.future)).single.quantityKg,
        940,
      );
    },
  );
}
