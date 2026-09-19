import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yield_app/main.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yield_app/app/app.dart';
import 'package:yield_app/core/location/current_location.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Farmer input is saved without fabricated recommendations', (
    tester,
  ) async {
    await app.main();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentLocationProvider.overrideWithValue(
            () async => (latitude: 13.55, longitude: 78.5),
          ),
        ],
        child: const HarvestTwinApp(),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tap(String label) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final finder = find.text(label).first;
      await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap('Register Harvest');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Net weight'),
      '725',
    );
    await tap('Current location');
    await tap('Review facts');
    await tap('Confirm facts & see recommendation');
    expect(find.text('Harvest saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
