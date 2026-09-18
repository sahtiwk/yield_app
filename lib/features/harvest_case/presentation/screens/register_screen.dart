import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../controllers/harvest_controller.dart';
import '../widgets/harvest_editor.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(draftProvider);
    final session = ref.watch(sessionProvider);
    final prefs = ref.watch(preferencesProvider);
    final busy = session.isLoading;
    void edit() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const HarvestEditor(),
    );
    Future<void> confirm() async {
      final success = await ref.read(sessionProvider.notifier).confirm();
      if (context.mounted && success) context.go('/decisions');
    }

    return StackItems(
      gap: 22,
      children: [
        Panel(
          color: Palette.surface,
          child: StackItems(
            gap: 10,
            children: [
              const Heading(
                'Register today’s harvest',
                icon: Icons.record_voice_over_outlined,
                trailing: Tag('Step 2 of 2'),
              ),
              const Text(
                'Your harvest. Your knowledge. A clearer next step.',
                style: TextStyle(
                  color: Palette.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ResponsiveColumns(
          main: StackItems(
            children: [
              Panel(
                child: StackItems(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Palette.pale,
                        ),
                        child: IconButton.filled(
                          tooltip: 'Preview voice entry',
                          iconSize: 32,
                          padding: const EdgeInsets.all(22),
                          onPressed: busy
                              ? null
                              : () => _voicePreview(context, ref),
                          icon: Icon(
                            prefs.voice
                                ? Icons.mic_none
                                : Icons.keyboard_outlined,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Tag(
                        prefs.voice
                            ? '${prefs.language} voice · demo preview'
                            : 'Manual entry mode',
                        color: Palette.surface,
                        icon: Icons.circle,
                      ),
                    ),
                    Panel(
                      color: Palette.surface,
                      padding: 16,
                      child: StackItems(
                        gap: 12,
                        children: [
                          const Heading(
                            'Farmer’s harvest notes',
                            icon: Icons.record_voice_over_outlined,
                          ),
                          Text(
                            '“I have ${draft.quantityKg.toStringAsFixed(0)} kg of ${draft.crop.name.toLowerCase()}. The crop is ${draft.farmerCondition.toLowerCase()}. ${draft.urgency}. My usual plan is ${draft.currentPlan}.”',
                            style: const TextStyle(
                              fontSize: 17,
                              color: Palette.ink,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                            ),
                          ),
                          const Divider(),
                          const Text(
                            'Example transcript · not a live recording',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Review the crop facts below. You can change every detail before confirming.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Notice(
                'Your judgment comes first. These are example values. Check and confirm your crop facts before continuing.',
                icon: Icons.verified_user_outlined,
              ),
              Panel(
                color: Palette.surface,
                child: StackItems(
                  gap: 12,
                  children: [
                    const Heading('Demo context ready', icon: Icons.radar),
                    const Text(
                      'Explore a sample comparison of nearby markets, travel costs, and storage options. Your entries are saved for this session.',
                    ),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Tag(
                          'Sample market data',
                          color: Colors.white,
                          icon: Icons.storefront,
                        ),
                        Tag(
                          'No live services',
                          color: Colors.white,
                          icon: Icons.cloud_off,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          side: StackItems(
            children: [
              Panel(
                child: StackItems(
                  children: [
                    Heading(
                      'Confirm crop facts',
                      icon: Icons.assignment_turned_in_outlined,
                      trailing: IconButton(
                        tooltip: 'Edit crop facts',
                        onPressed: busy ? null : edit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                    _Fact(
                      label: 'Commodity & variety',
                      value: '${draft.crop.name} · ${draft.crop.variety}',
                      icon: Icons.eco_outlined,
                      action: TextButton(
                        onPressed: busy ? null : edit,
                        child: const Text('Edit'),
                      ),
                    ),
                    Panel(
                      color: Palette.surface,
                      padding: 14,
                      child: StackItems(
                        gap: 6,
                        children: [
                          const Text('Harvested net weight'),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${draft.quantityKg.toStringAsFixed(0)} kg',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Decrease weight by 25 kg',
                                onPressed: busy || draft.quantityKg <= 25
                                    ? null
                                    : () => ref
                                          .read(draftProvider.notifier)
                                          .update(
                                            draft.copyWith(
                                              quantityKg: draft.quantityKg - 25,
                                            ),
                                          ),
                                icon: const Icon(Icons.remove),
                              ),
                              const SizedBox(width: 5),
                              IconButton.filledTonal(
                                tooltip: 'Increase weight by 25 kg',
                                onPressed: busy || draft.quantityKg > 99975
                                    ? null
                                    : () => ref
                                          .read(draftProvider.notifier)
                                          .update(
                                            draft.copyWith(
                                              quantityKg: draft.quantityKg + 25,
                                            ),
                                          ),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _Fact(
                      label: 'Harvesting window',
                      value:
                          '${draft.harvestStatus} · ${MaterialLocalizations.of(context).formatShortDate(draft.harvestedAt)}',
                      icon: Icons.wb_sunny_outlined,
                      action: TextButton(
                        onPressed: busy ? null : edit,
                        child: Text(
                          TimeOfDay.fromDateTime(
                            draft.harvestedAt,
                          ).format(context),
                        ),
                      ),
                    ),
                    Panel(
                      color: const Color(0xFFFFF3E9),
                      padding: 15,
                      child: StackItems(
                        gap: 8,
                        children: [
                          const Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              Text(
                                'Urgency & shelf life',
                                style: TextStyle(
                                  color: Palette.amber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Tag(
                                'Hard constraint',
                                color: Palette.peach,
                                foreground: Palette.amber,
                              ),
                            ],
                          ),
                          Text(
                            draft.urgency,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Text(
                            'Your selling deadline must be respected.',
                          ),
                        ],
                      ),
                    ),
                    _Fact(
                      label: 'Quality & firmness',
                      value: draft.farmerCondition,
                      icon: Icons.verified_outlined,
                      action: const Tag('Farmer declared', color: Palette.pale),
                    ),
                    _Fact(
                      label: 'Your current plan · baseline',
                      value: draft.currentPlan,
                      icon: Icons.storefront_outlined,
                    ),
                    _Fact(
                      label: 'Harvest location',
                      value: draft.location,
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              if (session.hasError)
                const Notice(
                  'We couldn’t load the example. Check your details and try again.',
                  icon: Icons.error_outline,
                  color: Palette.peach,
                ),
              if (busy)
                const Panel(
                  child: StackItems(
                    children: [
                      LinearProgressIndicator(),
                      Text(
                        'Preparing your example recommendation…',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              PrimaryButton(
                busy
                    ? 'Preparing your recommendation…'
                    : 'Confirm facts & see recommendation',
                icon: Icons.rocket_launch_outlined,
                onPressed: busy ? null : confirm,
              ),
              const Text(
                'Demo estimates are fixed examples, not quotes for your batch.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _voicePreview(context, ref),
                    icon: const Icon(Icons.mic_none),
                    label: const Text('Voice preview'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : edit,
                    icon: const Icon(Icons.keyboard_outlined),
                    label: const Text('Manual edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _voicePreview(
    BuildContext context,
    WidgetRef ref,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: StackItems(
          children: [
            const Icon(Icons.mic_none, size: 52, color: Palette.green),
            Text(
              'Voice entry preview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text(
              'No microphone is recording. Load the sample harvest to try the confirmation flow, or use manual entry for your own details.',
            ),
            PrimaryButton(
              'Load sample harvest',
              icon: Icons.refresh,
              onPressed: () {
                ref.read(draftProvider.notifier).reset();
                Navigator.pop(sheetContext);
              },
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Keep my details'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.icon,
    this.action,
  });
  final String label, value;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Panel(
    color: Palette.surface,
    padding: 13,
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Palette.green),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Palette.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ?action,
      ],
    ),
  );
}
