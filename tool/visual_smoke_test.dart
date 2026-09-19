import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yield_app/app/app.dart';
import 'package:yield_app/core/localization/app_localizations.dart';
import 'package:yield_app/features/home/presentation/home_controller.dart';
import 'package:yield_app/features/harvest_case/presentation/controllers/harvest_controller.dart';

void main() {
  testWidgets('Capture primary screens with bundled fonts', (tester) async {
    await tester.runAsync(() async {
      for (final family in [
        'Poppins',
        'NotoSansTelugu',
        'NotoSansDevanagari',
        'NotoSansTamil',
      ]) {
        final loader = FontLoader(family);
        final paths = family == 'Poppins'
            ? [
                'Poppins-Regular.ttf',
                'Poppins-SemiBold.ttf',
                'Poppins-Bold.ttf',
              ]
            : ['$family.ttf'];
        for (final path in paths) {
          loader.addFont(
            File('assets/fonts/$path').readAsBytes().then(ByteData.sublistView),
          );
        }
        await loader.load();
      }
      final sdk = Platform.environment['FLUTTER_ROOT'] ?? '.tools/flutter';
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await icons.load();
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final capture = GlobalKey();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: UncontrolledProviderScope(
          container: container,
          child: const HarvestTwinApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> save(String name) async {
      await tester.runAsync(() async {
        final image =
            await (capture.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts').create(recursive: true);
        await File(
          'artifacts/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await save('home-mobile');
    container.read(preferencesProvider.notifier).language('Tamil');
    await tester.pumpAndSettle();
    await save('home-tamil-mobile');
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pumpAndSettle();
    await save('settings-tamil-mobile');
    container.read(preferencesProvider.notifier).language('English');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register').last);
    await tester.pumpAndSettle();
    await save('register-mobile');
    container
        .read(draftProvider.notifier)
        .update(
          container
              .read(draftProvider)
              .copyWith(
                quantityKg: 725,
                location: 'Test location',
                currentPlan: 'Other test market',
              ),
        );
    await container.read(sessionProvider.notifier).confirm();
    await tester.tap(find.text('Decisions').last);
    await tester.pumpAndSettle();
    await save('decisions-mobile');
    container.read(preferencesProvider.notifier).language('Tamil');
    await tester.pumpAndSettle();
    await save('decisions-tamil-mobile');
    await tester.tap(find.byIcon(Icons.sensors).last);
    await tester.pumpAndSettle();
    await save('monitor-tamil-mobile');
    await Scrollable.ensureVisible(
      tester.element(find.text(const AppStrings('Tamil')('decision_tree'))),
    );
    await tester.tap(find.text(const AppStrings('Tamil')('decision_tree')));
    await tester.pumpAndSettle();
    await save('decision-tree-tamil-mobile');
    container.read(preferencesProvider.notifier).language('English');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await save('home-desktop');
    await Scrollable.ensureVisible(
      tester.element(
        find.text(const AppStrings('English')('hyderabad_prices')),
      ),
    );
    await tester.pumpAndSettle();
    await save('hyderabad-prices-desktop');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
