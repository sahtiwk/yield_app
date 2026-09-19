import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/workspace_widgets.dart';
import '../../harvest_case/presentation/controllers/harvest_controller.dart';
import '../domain/recommendation_snapshot.dart';

class LiveRecommendationScreen extends ConsumerStatefulWidget {
  const LiveRecommendationScreen({super.key, this.monitor = false});
  final bool monitor;
  @override
  ConsumerState<LiveRecommendationScreen> createState() =>
      _LiveRecommendationScreenState();
}

class _LiveRecommendationScreenState
    extends ConsumerState<LiveRecommendationScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.monitor) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted && _foreground) {
          ref.read(sessionProvider.notifier).refresh();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _foreground = state == AppLifecycleState.resumed;
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return ref
        .watch(sessionProvider)
        .when(
          loading: () => FeedbackState(
            icon: Icons.sync,
            title: t('Evaluating options'),
            busy: true,
          ),
          error: (_, _) => FeedbackState(
            icon: Icons.error_outline,
            title: t('save_failed'),
            action: () => context.go('/register'),
            actionLabel: t('Edit'),
          ),
          data: (session) {
            if (session == null) {
              return FeedbackState(
                icon: Icons.inventory_2_outlined,
                title: t('No harvest selected'),
                action: () => context.go('/cases'),
                actionLabel: t('My Cases'),
              );
            }
            final c = session.harvestCase;
            final r = session.recommendation;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkspaceHeading(
                  title: t(widget.monitor ? 'Monitor' : 'Decisions'),
                  subtitle:
                      '${t(c.crop.name)} · ${c.crop.variety} · ${t.format('weight_value', {'value': t.number(c.quantityKg)})}',
                  action: IconButton(
                    tooltip: t('Refresh estimate'),
                    onPressed: session.refreshing
                        ? null
                        : () => ref.read(sessionProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const SizedBox(height: 24),
                if (session.refreshing) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 16),
                ],
                if (session.issue != null) ...[
                  StatusMessage(
                    icon: Icons.info_outline,
                    text: t(session.issue!),
                    warning: true,
                  ),
                  if (r != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(t('Previous estimate')),
                    ),
                  const SizedBox(height: 20),
                ],
                if (r == null) ...[
                  if (!session.refreshing)
                    FeedbackState(
                      icon: Icons.task_alt,
                      title: t('Harvest saved'),
                    ),
                  Text('${t('Selling deadline')}: ${t(c.urgency)}'),
                  Text('${t('Quality assessment')}: ${t(c.farmerCondition)}'),
                ] else ...[
                  if (session.changed) ...[
                    StatusMessage(
                      icon: Icons.update,
                      text: t('Recommendation updated'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    color: Palette.pale,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('Recommended option'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t(r.best.action),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.best.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          t.format('distance_time', {
                            'distance': t.number(r.best.distanceKm),
                            'hours': t.number(r.best.travelHours),
                          }),
                        ),
                        const SizedBox(height: 24),
                        Text(t('Estimated net value')),
                        const SizedBox(height: 4),
                        Text(
                          t.money(r.best.netValue),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        Text(
                          '${t('Range')}: ${t.money(r.best.low)} – ${t.money(r.best.high)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 32,
                    runSpacing: 20,
                    children: [
                      _Metric(
                        t('Baseline'),
                        r.baselineValue == null
                            ? t('Not available')
                            : t.money(r.baselineValue!),
                      ),
                      _Metric(
                        t('Difference'),
                        r.valueDifference == null
                            ? t('Not available')
                            : t.money(r.valueDifference!),
                      ),
                      _Metric(t('Selling deadline'), t(c.urgency)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 32),
                  Text(
                    t('Ranked options'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in [r.best, ...r.alternatives].indexed)
                    _ScenarioTile(scenario: entry.$2, rank: entry.$1 + 1, t: t),
                  const SizedBox(height: 20),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Text(t('Estimate details & assumptions')),
                    leading: const Icon(Icons.fact_check_outlined),
                    children: [
                      for (final code in r.assumptionCodes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(t(code)),
                          ),
                        ),
                      if (r.temperature != null)
                        _Metric(
                          t('Weather'),
                          '${t.number(r.temperature!)} °C${r.humidity == null ? '' : ' · ${t.number(r.humidity!)}%'}',
                        ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t('Sources'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      for (final source in r.sources)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SelectableText(source),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${t('Last checked')}: ${t.date(r.observedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                if (widget.monitor)
                  Text(
                    t('Automatic updates'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: session.refreshing
                          ? null
                          : () => ref.read(sessionProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh),
                      label: Text(t('Refresh estimate')),
                    ),
                    OutlinedButton.icon(
                      onPressed: session.refreshing
                          ? null
                          : () => context.go('/register'),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(t('Edit')),
                    ),
                    if (!widget.monitor)
                      TextButton.icon(
                        onPressed: () => context.go('/monitor'),
                        icon: const Icon(Icons.sensors),
                        label: Text(t('Monitor')),
                      ),
                    TextButton(
                      onPressed: () => context.go('/cases'),
                      child: Text(t('My Cases')),
                    ),
                  ],
                ),
              ],
            );
          },
        );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.scenario,
    required this.rank,
    required this.t,
  });
  final ScenarioResult scenario;
  final int rank;
  final AppStrings t;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rank == 1 ? Palette.green : const Color(0xFFDCE3DD),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.format('rank_label', {'rank': t.number(rank)}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  scenario.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  t.money(scenario.netValue),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(t(scenario.action)),
            Text(
              t.format('distance_time', {
                'distance': t.number(scenario.distanceKm),
                'hours': t.number(scenario.travelHours),
              }),
            ),
          ],
        ),
      ),
    ),
  );
}
