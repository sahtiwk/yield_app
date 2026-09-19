import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yield_app/app/app.dart';
import 'package:yield_app/core/location/current_location.dart';
import 'package:yield_app/core/localization/app_localizations.dart';
import 'package:yield_app/core/localization/decision_translations.dart';
import 'package:yield_app/features/harvest_case/domain/harvest_case.dart';
import 'package:yield_app/features/harvest_case/presentation/controllers/harvest_controller.dart';
import 'package:yield_app/features/home/presentation/home_controller.dart';
import 'package:yield_app/features/recommendation/domain/recommendation_snapshot.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class TestRecommendations implements RecommendationRepository {
  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase c) async =>
      RecommendationSnapshot(
        caseId: c.id,
        best: const ScenarioResult(
          id: 'market-test',
          name: 'Test market',
          action: 'direct_buyer',
          netValue: 12000,
          low: 10800,
          high: 13200,
          distanceKm: 12,
          travelHours: .5,
        ),
        alternatives: const [
          ScenarioResult(
            id: 'other-test',
            name: 'Other test market',
            action: 'sell_today',
            netValue: 11000,
            low: 9900,
            high: 12100,
            distanceKm: 18,
            travelHours: .7,
          ),
        ],
        baselineValue: 11000,
        valueDifference: 1000,
        observedAt: DateTime(2026, 9, 19, 10),
        assumptionCodes: const [
          'estimate_caution',
          'reference_decay',
          'sensitivity_range',
          'storage_not_ranked',
          'baseline_unmatched',
        ],
        sources: const ['Test source'],
        temperature: 28,
        humidity: 65,
      );
}

void main() {
  for (final language in ['English', 'Hindi', 'Tamil', 'Telugu']) {
    testWidgets('Saving $language returns home and localizes market content', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HarvestTwinApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<String> && widget.value == language,
        ),
      );
      final t = AppStrings(language);
      await tapVisible(tester, find.text(t('Save')));
      expect(container.read(preferencesProvider).language, language);
      expect(find.text(t('Your workspace')), findsOneWidget);
      expect(find.text(t('hyderabad_prices')), findsOneWidget);
      expect(find.text(t('Choose your language')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  test('Provider labels never fall back to English in other languages', () {
    for (final language in ['Hindi', 'Tamil', 'Telugu']) {
      final t = AppStrings(language);
      expect(
        t.externalLabel('Untranslated incoming market', 'market_destination'),
        t('market_destination'),
      );
      expect(t.externalLabel('Arka Rakshak', 'Variety'), isNot('Arka Rakshak'));
    }
  });
  testWidgets(
    'Current location captures coordinates without manual fields or a plan',
    (tester) async {
      var requests = 0;
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWithValue(() async {
            requests++;
            return (latitude: 13.55, longitude: 78.5);
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HarvestTwinApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Register Harvest'));
      expect(requests, 0);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Net weight'),
        '125',
      );
      await tapVisible(tester, find.text('Current location'));
      expect(requests, 1);
      expect(
        find.widgetWithText(TextFormField, 'Farm / harvest location'),
        findsNothing,
      );
      await tapVisible(tester, find.text('Review facts'));
      final draft = container.read(draftProvider);
      expect(draft.latitude, 13.55);
      expect(draft.longitude, 78.5);
      expect(draft.currentPlan, isEmpty);
      await tapVisible(tester, find.text('Confirm facts & see recommendation'));
      expect(find.text('Published price reference'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('All decision messages have four nonempty translations', () {
    for (final translations in decisionTranslations.values) {
      expect(translations.length, 4);
      expect(translations.every((text) => text.trim().isNotEmpty), true);
    }
  });
  testWidgets(
    'Registration validates, saves and shows a dated crop price reference',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWithValue(
            () async => throw StateError('denied'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HarvestTwinApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Register Harvest'));
      await tapVisible(tester, find.text('Review facts'));
      expect(
        find.text('Enter a weight between 1 and 100,000 kg'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Net weight'),
        '725',
      );
      expect(find.text('Your current selling plan'), findsNothing);
      expect(
        find.widgetWithText(TextFormField, 'Farm / harvest location'),
        findsNothing,
      );
      await tapVisible(tester, find.text('Current location'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Farm / harvest location'),
        'Village',
      );
      await tapVisible(tester, find.text('Review facts'));
      expect(find.text('725 kg'), findsOneWidget);
      await tapVisible(tester, find.text('Confirm facts & see recommendation'));
      expect(find.text('Published price reference'), findsOneWidget);
      expect(
        container
            .read(sessionProvider)
            .requireValue!
            .recommendation!
            .isReference,
        true,
      );
      expect(find.textContaining('Demo'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [360.0, 390.0, 768.0, 1024.0, 1440.0]) {
    for (final language in ['English', 'Hindi', 'Tamil', 'Telugu']) {
      testWidgets('Localized decisions and monitor fit $language at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer(
          overrides: [
            recommendationRepositoryProvider.overrideWithValue(
              TestRecommendations(),
            ),
          ],
        );
        addTearDown(container.dispose);
        final t = AppStrings(language);
        container.read(preferencesProvider.notifier).language(language);
        container
            .read(draftProvider.notifier)
            .update(
              container
                  .read(draftProvider)
                  .copyWith(
                    quantityKg: 725,
                    location: 'Test village',
                    currentPlan: 'Other test market',
                  ),
            );
        await container.read(sessionProvider.notifier).confirm();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const HarvestTwinApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text(t('Decisions')).last);
        expect(find.text(t('direct_buyer')), findsWidgets);
        expect(find.text(t.money(12000)), findsWidgets);
        await tapVisible(
          tester,
          find.text(t('Estimate details & assumptions')),
        );
        expect(find.text(t('estimate_caution')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text(t('Monitor')).last);
        expect(find.text(t('Ranked options')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.byTooltip(t('Settings')));
        expect(find.byType(RadioListTile<String>), findsNWidgets(4));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('Cases and markets do not manufacture observations', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HarvestTwinApp()));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('My Cases').first);
    expect(find.text('No harvests yet'), findsOneWidget);
    await tapVisible(tester, find.text('Home').last);
    await tapVisible(tester, find.text('Market Prices').first);
    expect(
      find.text(const AppStrings('English')('No prices available')),
      findsOneWidget,
    );
  });
}
