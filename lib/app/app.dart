import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class HarvestTwinApp extends StatefulWidget {
  const HarvestTwinApp({super.key});
  @override
  State<HarvestTwinApp> createState() => _HarvestTwinAppState();
}

class _HarvestTwinAppState extends State<HarvestTwinApp> {
  late final GoRouter _router = createRouter();
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Harvest Twin',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: _router,
  );
}
