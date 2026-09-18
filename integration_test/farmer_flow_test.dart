import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yield_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Farmer flow works on an Android device', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await binding.takeScreenshot('01-settings');
    await tap(find.text('తెలుగు'));
    await tap(find.text('Standard visual mode'));
    await tap(find.text('Continue to register harvest'));
    expect(find.text('Confirm crop facts'), findsOneWidget);
    await binding.takeScreenshot('02-register');

    await tap(find.text('Manual edit'));
    final weight = find.widgetWithText(TextFormField, 'Net weight');
    await tester.enterText(weight, '0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tap(find.text('Save crop facts'));
    expect(
      find.text('Enter a weight between 1 and 100,000 kg'),
      findsOneWidget,
    );
    await tester.enterText(weight, '725');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tap(find.text('Save crop facts'));
    expect(find.text('725 kg'), findsOneWidget);
    await tap(find.text('Confirm facts & see recommendation'));
    expect(find.text('SELL TODAY'), findsOneWidget);
    await binding.takeScreenshot('03-recommendation');

    await tap(find.text('Estimate details & assumptions'));
    expect(
      find.textContaining('Market acceptance, buyer availability'),
      findsOneWidget,
    );
    await tap(find.text('View route & buyer details'));
    expect(find.text('Route & buyer details'), findsOneWidget);
    await tap(find.text('Done'));
    await tap(find.text('Monitor this harvest'));
    await tap(find.text('Simulate a 5°C heat spike'));
    expect(find.text('Recommendation changed!'), findsOneWidget);
    await tester.ensureVisible(find.text('Recommendation changed!'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04-monitor-alert');
    await tap(find.text('Keep original plan'));
    await tap(find.text('Review change'));
    await tap(find.text('Accept route change'));
    expect(
      find.text(
        'Route change accepted for this demo. No booking has been made.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
