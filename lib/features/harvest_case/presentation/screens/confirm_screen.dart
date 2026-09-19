import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/supabase/app_failure.dart';
import '../../../../core/widgets/components.dart';
import '../controllers/harvest_controller.dart';

class ConfirmScreen extends ConsumerWidget {
  const ConfirmScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(draftProvider);
    final session = ref.watch(sessionProvider);
    final t = ref.watch(stringsProvider);
    final busy = session.isLoading || session.value?.refreshing == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('Confirm crop facts'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        for (final fact in [
          (label: 'Crop', value: t(c.crop.name)),
          (
            label: 'Net weight',
            value: t.format('weight_value', {'value': t.number(c.quantityKg)}),
          ),
          (label: 'Variety', value: t.externalLabel(c.crop.variety, 'Variety')),
          (label: 'Harvest status', value: t(c.harvestStatus)),
          (
            label: 'Harvest date',
            value: MaterialLocalizations.of(
              context,
            ).formatShortDate(c.harvestedAt),
          ),
          (label: 'Your assessment of quality', value: t(c.farmerCondition)),
          (label: 'Selling deadline', value: t(c.urgency)),
          (label: 'Farm / harvest location', value: c.location),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(fact.label)),
                const SizedBox(height: 4),
                Text(
                  fact.value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Divider(),
              ],
            ),
          ),
        if (session.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              t(
                session.error is AppFailure
                    ? (session.error as AppFailure).code
                    : 'save_failed',
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (busy) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        PrimaryButton(
          t('Confirm facts & see recommendation'),
          icon: Icons.check,
          onPressed: busy
              ? null
              : () async {
                  final success = await ref
                      .read(sessionProvider.notifier)
                      .confirm();
                  if (context.mounted && success) context.go('/decisions');
                },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : () => context.go('/register'),
          icon: const Icon(Icons.edit_outlined),
          label: Text(t('Edit')),
        ),
        TextButton(
          onPressed: () => context.go('/cases'),
          child: Text(t('My Cases')),
        ),
      ],
    );
  }
}
