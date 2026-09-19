import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_shell.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/harvest_case/presentation/screens/form_screen.dart';
import '../features/harvest_case/presentation/screens/confirm_screen.dart';
import '../features/recommendation/presentation/recommendation_screen.dart';
import '../features/monitor/presentation/monitor_screen.dart';
import '../features/auth/data/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/home/presentation/cases_screen.dart';
import '../features/home/presentation/market_screen.dart';

GoRouter createRouter(AuthController auth) => GoRouter(
  refreshListenable: auth,
  redirect: (context, state) {
    final path = state.uri.path;
    if (auth.offline) {
      return path == '/login' || path == '/onboarding' ? '/' : null;
    }
    if (auth.loading || auth.userId == null || auth.error != null) {
      return path == '/login' ? null : '/login';
    }
    if (!auth.onboarded) return path == '/onboarding' ? null : '/onboarding';
    return path == '/login' ||
            path == '/onboarding' ||
            path == '/login-callback/'
        ? '/'
        : null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, _) => ListenableBuilder(
        listenable: auth,
        builder: (_, _) => const LoginScreen(),
      ),
    ),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    for (final route in <({String path, Widget screen})>[
      (path: '/', screen: const HomeScreen()),
      (path: '/register', screen: const FormScreen()),
      (path: '/confirm', screen: const ConfirmScreen()),
      (path: '/decisions', screen: const RecommendationScreen()),
      (path: '/monitor', screen: const MonitorScreen()),
      (path: '/cases', screen: const CasesScreen()),
      (path: '/markets', screen: const MarketScreen()),
      (path: '/settings', screen: const OnboardingScreen(settings: true)),
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
