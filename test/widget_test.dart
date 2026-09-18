import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yield_app/app/app.dart';
import 'package:yield_app/features/harvest_case/presentation/controllers/harvest_controller.dart';
import 'package:yield_app/features/settings/presentation/settings_controller.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Full farmer flow preserves edits, shows a snapshot and handles a heat alert',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HarvestTwinApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('తెలుగు'));
      expect(container.read(preferencesProvider).language, 'Telugu');
      await tapVisible(tester, find.text('Standard visual mode'));
      expect(container.read(preferencesProvider).voice, false);
      await tapVisible(tester, find.text('Continue to register harvest'));
      expect(find.text('Confirm crop facts'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Increase weight by 25 kg'));
      expect(container.read(draftProvider).quantityKg, 675);
      await tapVisible(tester, find.text('Manual edit'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Net weight'),
        '0',
      );
      await tapVisible(tester, find.text('Save crop facts'));
      expect(
        find.text('Enter a weight between 1 and 100,000 kg'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Net weight'),
        '725',
      );
      await tapVisible(tester, find.text('Save crop facts'));
      expect(container.read(draftProvider).quantityKg, 725);
      await tester.ensureVisible(
        find.text('Confirm facts & see recommendation'),
      );
      await tester.tap(find.text('Confirm facts & see recommendation'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.text('SELL TODAY'), findsOneWidget);
      expect(
        container.read(sessionProvider).requireValue!.harvestCase.quantityKg,
        725,
      );
      await tapVisible(tester, find.text('Estimate details & assumptions'));
      expect(
        find.textContaining('Market acceptance, buyer availability'),
        findsOneWidget,
      );
      await tapVisible(tester, find.text('View route & buyer details'));
      expect(find.text('Route & buyer details'), findsOneWidget);
      await tapVisible(tester, find.text('Done'));
      await tapVisible(tester, find.text('Monitor this harvest'));
      await tapVisible(tester, find.text('Simulate a 5°C heat spike'));
      expect(find.text('Recommendation changed!'), findsOneWidget);
      await tapVisible(tester, find.text('Keep original plan'));
      await tapVisible(tester, find.text('Review change'));
      await tapVisible(tester, find.text('Accept route change'));
      expect(
        container.read(sessionProvider).requireValue!.decision,
        contains('accepted'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 390.0, 430.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('All four screens lay out at $width pixels', (tester) async {
      tester.view.physicalSize = Size(width, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HarvestTwinApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Register').last);
      expect(find.text('Confirm crop facts'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Confirm facts & see recommendation'));
      expect(find.text('SELL TODAY'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Monitor').last);
      await tapVisible(tester, find.text('Simulate a 5°C heat spike'));
      expect(find.text('Recommendation changed!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Unregistered cases show useful empty states', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HarvestTwinApp()));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Decisions').last);
    expect(find.text('Your harvest starts here'), findsOneWidget);
    await tapVisible(tester, find.text('Monitor').last);
    expect(find.text('Register a harvest'), findsOneWidget);
  });
}
