import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../controllers/harvest_controller.dart';

class HarvestSelector extends ConsumerWidget {
  const HarvestSelector({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('select_harvest'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        ref
            .watch(activeCasesProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(activeCasesProvider),
                child: Text(t('Try again')),
              ),
              data: (cases) => Column(
                children: [
                  if (cases.isEmpty) Text(t('No harvests yet')),
                  for (final c in cases)
                    ListTile(
                      leading: const Icon(Icons.eco_outlined),
                      title: Text(
                        '${t(c.crop.name)} | ${t.format('weight_value', {'value': t.number(c.quantityKg)})}',
                      ),
                      subtitle: Text(
                        '${t(c.harvestStatus)} | ${t.date(c.harvestedAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          ref.read(sessionProvider.notifier).openCase(c),
                    ),
                ],
              ),
            ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            ref.read(draftProvider.notifier).reset();
            context.go('/register');
          },
          icon: const Icon(Icons.add),
          label: Text(t('Register Harvest')),
        ),
      ],
    );
  }
}
