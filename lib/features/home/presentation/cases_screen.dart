import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../harvest_case/presentation/controllers/harvest_controller.dart';

class CasesScreen extends ConsumerWidget {
  const CasesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t('My Cases'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: t('Try again'),
              onPressed: () => ref.invalidate(activeCasesProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ref
            .watch(activeCasesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(activeCasesProvider),
                child: Text(t('Try again')),
              ),
              data: (cases) => cases.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(t('No harvests yet')),
                    )
                  : Column(
                      children: [
                        for (final c in cases)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            leading: const Icon(Icons.eco_outlined),
                            title: Text(
                              '${t(c.crop.name)} · ${t.format('weight_value', {'value': t.number(c.quantityKg)})}',
                            ),
                            subtitle: Text('${c.location}\n${t(c.urgency)}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ref.read(sessionProvider.notifier).openCase(c);
                              context.go('/monitor');
                            },
                          ),
                      ],
                    ),
            ),
      ],
    );
  }
}
