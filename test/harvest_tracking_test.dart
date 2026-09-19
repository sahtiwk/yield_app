import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yield_app/app/app.dart';
import 'package:yield_app/core/supabase/app_failure.dart';
import 'package:yield_app/features/home/presentation/home_controller.dart';
import 'package:yield_app/features/harvest_case/data/local_harvest_case_repository.dart';
import 'package:yield_app/features/harvest_case/presentation/controllers/harvest_controller.dart';
import 'package:yield_app/features/recommendation/data/reference_recommendation_repository.dart';
import 'package:yield_app/shared/models/crop_catalog.dart';
import 'widget_test.dart' show tapVisible;

void main() {
  test(
    'Crop-specific quotes are deterministic and persisted without fake offers',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = ReferenceRecommendationRepository(prefs);
      for (final crop in cropCatalog) {
        final c = newHarvestDraft().copyWith(
          crop: crop,
          quantityKg: 100,
          location: 'Farm',
        );
        final result = await repo.evaluate(c);
        expect(result.isReference, true);
        expect(
          result.best.netValue,
          closeTo(result.referenceUnitPrice! * 100, .001),
        );
        expect(result.observedAt, DateTime.utc(2026, 9, 14));
        expect(result.alternatives, isEmpty);
        expect(result.temperature, isNull);
        final stored =
            jsonDecode(prefs.getString('reference_quote_${c.id}')!) as Map;
        expect(stored['crop_id'], crop.id);
        expect(stored['quantity_kg'], 100);
        expect(
          (await ReferenceRecommendationRepository(
            prefs,
          ).evaluate(c)).best.netValue,
          result.best.netValue,
        );
      }
    },
  );

  test(
    'Timing updates persist the same case across restart and reject future completed harvest',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [localPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final draft = container
          .read(draftProvider)
          .copyWith(quantityKg: 120, location: 'Farm');
      container.read(draftProvider.notifier).update(draft);
      await container.read(sessionProvider.notifier).confirm();
      await Future<void>.delayed(Duration.zero);
      final future = DateTime.now().add(const Duration(days: 2));
      expect(
        await container
            .read(sessionProvider.notifier)
            .updateTiming('Harvest planned', future),
        true,
      );
      final saved = (await LocalHarvestCaseRepository(
        prefs,
      ).getActiveCases()).single;
      expect(saved.id, draft.id);
      expect(saved.harvestStatus, 'Harvest planned');
      expect(saved.harvestedAt, future);
      await expectLater(
        container
            .read(sessionProvider.notifier)
            .updateTiming('Harvested', future),
        throwsA(isA<AppFailure>()),
      );
      expect(
        (await LocalHarvestCaseRepository(
          prefs,
        ).getActiveCases()).single.harvestStatus,
        'Harvest planned',
      );
    },
  );

  testWidgets(
    'User selects saved harvest, expands tree, edits timing and reopens it',
    (tester) async {
      final repo = LocalHarvestCaseRepository(null);
      final c = await repo.confirm(
        repo.createDraft().copyWith(
          quantityKg: 250,
          location: 'Farm',
          harvestedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      );
      final container = ProviderContainer(
        overrides: [harvestRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HarvestTwinApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Decisions').last);
      expect(find.text('Choose a saved harvest'), findsOneWidget);
      expect(find.text('Published price reference'), findsNothing);
      await tapVisible(tester, find.byType(ListTile).first);
      expect(find.text('Published price reference'), findsOneWidget);
      expect(find.text('Location & routes'), findsNothing);
      await tapVisible(tester, find.text('Decision pathway'));
      expect(find.text('Location & routes'), findsOneWidget);
      await tapVisible(tester, find.text('Monitor').last);
      expect(find.textContaining('Harvested on'), findsOneWidget);
      await tapVisible(tester, find.text('Update harvest timing'));
      await tapVisible(tester, find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.text('Harvest planned').last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      expect(
        (await repo.getActiveCases()).single.harvestStatus,
        'Harvest planned',
      );
      await tapVisible(tester, find.text('Change harvest'));
      expect(find.text('Choose a saved harvest'), findsOneWidget);
      await container
          .read(sessionProvider.notifier)
          .openCase((await repo.getActiveCases()).single);
      await tester.pumpAndSettle();
      expect(find.textContaining('Planned harvest:'), findsOneWidget);
      expect(
        container.read(sessionProvider).requireValue!.harvestCase.id,
        c.id,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
