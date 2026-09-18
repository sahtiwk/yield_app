import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../features/settings/presentation/settings_controller.dart';
import 'components.dart';

const destinations = [
  (
    path: '/',
    label: 'Settings',
    title: 'Language & voice',
    icon: Icons.translate,
  ),
  (
    path: '/register',
    label: 'Register',
    title: 'Harvest registration',
    icon: Icons.add_circle_outline,
  ),
  (
    path: '/decisions',
    label: 'Decisions',
    title: 'Your recommendation',
    icon: Icons.insights_outlined,
  ),
  (
    path: '/monitor',
    label: 'Monitor',
    title: 'Case monitor',
    icon: Icons.sensors,
  ),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.path});
  final Widget child;
  final String path;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final index = destinations.indexWhere((d) => d.path == path);
    final selected = index < 0 ? 0 : index;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Palette.background,
                border: Border(bottom: BorderSide(color: Color(0xFFE7ECE7))),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Palette.green,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.spa,
                            color: Palette.orange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Harvest Twin',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Palette.green,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              Text(
                                'Post-harvest decision engine',
                                style: TextStyle(
                                  fontSize: wide ? 12 : 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Tag(
                          'Demo',
                          color: Palette.surface,
                          icon: Icons.circle,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'About your demo profile',
                          onPressed: () => showInfo(
                            context,
                            'Your demo workspace',
                            'Explore Harvest Twin with synthetic local data. Your changes stay in this session. No account or live service is connected.',
                          ),
                          icon: const CircleAvatar(
                            radius: 17,
                            backgroundColor: Palette.mint,
                            child: Icon(
                              Icons.person_outline,
                              color: Palette.green,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    NavigationRail(
                      selectedIndex: selected,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Palette.background,
                      indicatorColor: Palette.mint,
                      onDestinationSelected: (i) =>
                          context.go(destinations[i].path),
                      destinations: [
                        for (final d in destinations)
                          NavigationRailDestination(
                            icon: Icon(d.icon),
                            label: Text(d.label),
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
                            padding: EdgeInsets.fromLTRB(
                              wide ? 32 : 16,
                              18,
                              wide ? 32 : 16,
                              32,
                            ),
                            child: StackItems(
                              gap: 22,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ActionChip(
                                      avatar: Icon(
                                        prefs.voice
                                            ? Icons.volume_up_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        prefs.voice
                                            ? 'Voice mode · demo'
                                            : 'Visual mode',
                                      ),
                                      backgroundColor: Palette.mint,
                                      side: BorderSide.none,
                                      onPressed: () => ref
                                          .read(preferencesProvider.notifier)
                                          .voice(!prefs.voice),
                                    ),
                                    Text(
                                      destinations[selected].title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              height: 78,
              backgroundColor: Palette.background,
              indicatorColor: Palette.mint,
              onDestinationSelected: (i) => context.go(destinations[i].path),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            ),
    );
  }
}
