import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yield_app/features/harvest_case/data/mock_harvest_case_repository.dart';
import 'package:yield_app/features/harvest_case/domain/harvest_case.dart';
import 'package:yield_app/features/harvest_case/presentation/controllers/harvest_controller.dart';
import 'package:yield_app/features/recommendation/domain/recommendation_snapshot.dart';

class UnavailableRecommendationRepository implements RecommendationRepository {
  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase harvestCase) async =>
      throw StateError('Demo fixture unavailable');
  @override
  Future<RecommendationSnapshot> simulateChange(
    HarvestCase harvestCase,
  ) async => throw StateError('Demo fixture unavailable');
}

void main() {
  test(
    'Invalid and nonfinite weights are rejected at the repository boundary',
    () async {
      final repository = MockHarvestCaseRepository();
      for (final weight in [0.0, -1.0, double.nan, double.infinity]) {
        await expectLater(
          repository.confirm(
            repository.createDraft().copyWith(quantityKg: weight),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'A failed recommendation exposes an error without discarding farmer facts',
    () async {
      final container = ProviderContainer(
        overrides: [
          recommendationRepositoryProvider.overrideWithValue(
            UnavailableRecommendationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final original = container
          .read(draftProvider)
          .copyWith(quantityKg: 940, farmerCondition: 'Very ripe');
      container.read(draftProvider.notifier).update(original);
      expect(await container.read(sessionProvider.notifier).confirm(), false);
      expect(container.read(sessionProvider).hasError, true);
      expect(container.read(draftProvider).quantityKg, 940);
      expect(container.read(draftProvider).farmerCondition, 'Very ripe');
    },
  );
}
