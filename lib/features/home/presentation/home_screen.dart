import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/workspace_widgets.dart';
import '../../harvest_case/presentation/controllers/harvest_controller.dart';
import 'hyderabad_prices.dart';
import 'market_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final cases = ref.watch(activeCasesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceHeading(
          title: t('Your workspace'),
          subtitle: t('Your harvest, your next step'),
          action: IconButton(
            tooltip: t('Try again'),
            onPressed: () => ref.invalidate(activeCasesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 650 ? 2 : 1;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final item in [
                  (
                    title: 'Register Harvest',
                    icon: Icons.add_circle_outline,
                    route: '/register',
                    color: Palette.green,
                  ),
                  (
                    title: 'My Cases',
                    icon: Icons.inventory_2_outlined,
                    route: '/cases',
                    color: const Color(0xFF386AA5),
                  ),
                  (
                    title: 'Market Prices',
                    icon: Icons.storefront_outlined,
                    route: '/markets',
                    color: Palette.amber,
                  ),
                  (
                    title: 'Settings',
                    icon: Icons.tune,
                    route: '/settings',
                    color: const Color(0xFF705E83),
                  ),
                ])
                  SizedBox(
                    width: (box.maxWidth - (columns - 1) * 16) / columns,
                    child: _WorkspaceAction(
                      title: t(item.title),
                      icon: item.icon,
                      color: item.color,
                      onTap: () {
                        if (item.route == '/register') {
                          ref.read(draftProvider.notifier).reset();
                        }
                        context.go(item.route);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: Text(
                t('Active harvests'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/cases'),
              child: Text(t('My Cases')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        cases.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, _) => StatusMessage(
            icon: Icons.cloud_off_outlined,
            text: t('Unable to load'),
            warning: true,
          ),
          data: (rows) => rows.isEmpty
              ? FeedbackState(
                  icon: Icons.eco_outlined,
                  title: t('No harvests yet'),
                  action: () => context.go('/register'),
                  actionLabel: t('Add your first harvest'),
                )
              : Column(
                  children: [
                    for (final c in rows.take(3))
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: const Icon(
                          Icons.eco_outlined,
                          color: Palette.green,
                        ),
                        title: Text(
                          '${t(c.crop.name)} · ${t.format('weight_value', {'value': t.number(c.quantityKg)})}',
                        ),
                        subtitle: Text('${c.location} · ${t(c.urgency)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ref.read(sessionProvider.notifier).openCase(c);
                          context.go('/monitor');
                        },
                      ),
                  ],
                ),
        ),
        const Divider(height: 40),
        const MarketScreen(compact: true),
        const SizedBox(height: 24),
        const HyderabadPrices(),
      ],
    );
  }
}

class _WorkspaceAction extends StatefulWidget {
  const _WorkspaceAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  State<_WorkspaceAction> createState() => _WorkspaceActionState();
}

class _WorkspaceActionState extends State<_WorkspaceAction> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 160),
    constraints: const BoxConstraints(minHeight: 116),
    decoration: BoxDecoration(
      color: hover ? widget.color.withValues(alpha: .05) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: hover ? widget.color : const Color(0xFFDEE5E1)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onHover: (value) => setState(() => hover = value),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward, size: 20, color: widget.color),
            ],
          ),
        ),
      ),
    ),
  );
}
