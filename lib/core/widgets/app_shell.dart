import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../localization/app_localizations.dart';

const destinations = [
  (path: '/', label: 'Home', icon: Icons.home_outlined),
  (path: '/register', label: 'Register', icon: Icons.add_circle_outline),
  (path: '/decisions', label: 'Decisions', icon: Icons.insights_outlined),
  (path: '/monitor', label: 'Monitor', icon: Icons.sensors),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.path});
  final Widget child;
  final String path;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final index = destinations.indexWhere((d) => d.path == path);
    final selected = index < 0 ? 0 : index;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest Twin'),
        leading: const Icon(Icons.spa, color: Palette.green),
        actions: [
          IconButton(
            tooltip: t('Settings'),
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: selected,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => context.go(destinations[i].path),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(t(d.label)),
                    ),
                ],
              ),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(path),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: EdgeInsets.all(wide ? 32 : 16),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(path),
                        tween: Tween(begin: 0, end: 1),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        builder: (context, value, child) =>
                            Opacity(opacity: value, child: child),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) => context.go(destinations[i].path),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: t(d.label)),
              ],
            ),
    );
  }
}
