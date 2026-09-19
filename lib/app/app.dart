import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../features/auth/data/auth_controller.dart';
import '../features/auth/data/profile_provider.dart';
import '../features/home/presentation/home_controller.dart';
import '../features/harvest_case/presentation/controllers/harvest_controller.dart';
import '../features/home/presentation/market_screen.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class HarvestTwinApp extends ConsumerStatefulWidget {
  const HarvestTwinApp({super.key});
  @override
  ConsumerState<HarvestTwinApp> createState() => _HarvestTwinAppState();
}

class _HarvestTwinAppState extends ConsumerState<HarvestTwinApp> {
  late final GoRouter _router = createRouter(ref.read(authControllerProvider));
  late final AuthController _auth;
  String? _userId;
  @override
  void initState() {
    super.initState();
    _auth = ref.read(authControllerProvider);
    _userId = _auth.userId;
    _auth.addListener(_authChanged);
  }

  void _authChanged() {
    if (!mounted) return;
    final id = _auth.userId;
    if (id == _userId) return;
    _userId = id;
    ref.invalidate(harvestRepositoryProvider);
    ref.invalidate(activeCasesProvider);
    ref.invalidate(draftProvider);
    ref.invalidate(sessionProvider);
    ref.invalidate(marketPricesProvider);
    ref.invalidate(userProfileProvider);
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Harvest Twin',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: Locale(
      const {'English': 'en', 'Hindi': 'hi', 'Tamil': 'ta', 'Telugu': 'te'}[ref
              .watch(preferencesProvider)
              .language] ??
          'en',
    ),
    supportedLocales: const [
      Locale('en'),
      Locale('hi'),
      Locale('ta'),
      Locale('te'),
    ],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: _router,
  );
}
