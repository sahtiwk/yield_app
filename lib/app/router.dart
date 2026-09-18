import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_shell.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/harvest_case/presentation/screens/form_screen.dart';
import '../features/harvest_case/presentation/screens/confirm_screen.dart';
import '../features/recommendation/presentation/recommendation_screen.dart';
import '../features/monitor/presentation/monitor_screen.dart';

GoRouter createRouter() => GoRouter(
  routes: [
    for (final route in <({String path, Widget screen})>[
      (path: '/', screen: const HomeScreen()),
      (path: '/register', screen: const FormScreen()),
      (path: '/confirm', screen: const ConfirmScreen()),
      (path: '/decisions', screen: const RecommendationScreen()),
      (path: '/monitor', screen: const MonitorScreen()),
    ])
      GoRoute(
        path: route.path,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: AppShell(path: state.uri.path, child: route.screen),
        ),
      ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => context.go('/'),
        child: const Text('Return to Harvest Twin'),
      ),
    ),
  ),
);
