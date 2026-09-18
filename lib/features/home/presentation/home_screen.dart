import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../harvest_case/presentation/controllers/harvest_controller.dart';
import 'home_controller.dart';

const _languages = [
  (
    name: 'Telugu',
    native: 'తెలుగు',
    region: 'Telugu · South hubs',
    greeting: 'నమస్కారం రైతు మిత్రమా, మీ పంటను నమోదు చేయండి.',
  ),
  (
    name: 'Hindi',
    native: 'हिंदी',
    region: 'Hindi · North & central mandis',
    greeting: 'नमस्ते किसान साथी, अपनी फसल दर्ज करें।',
  ),
  (
    name: 'Kannada',
    native: 'ಕನ್ನಡ',
    region: 'Kannada · Southern APMC network',
    greeting: 'ನಮಸ್ಕಾರ, ನಿಮ್ಮ ಸುಗ್ಗಿಯನ್ನು ನೋಂದಾಯಿಸಿ.',
  ),
  (
    name: 'Tamil',
    native: 'தமிழ்',
    region: 'Tamil · Uzhavar Sandhai & hubs',
    greeting: 'வணக்கம், உங்கள் அறுவடையை பதிவு செய்யுங்கள்.',
  ),
  (
    name: 'Marathi',
    native: 'मराठी',
    region: 'Marathi · Western APMC hubs',
    greeting: 'नमस्कार शेतकरी मित्रा, तुमच्या पिकाची नोंद करा.',
  ),
  (
    name: 'English',
    native: 'English',
    region: 'Indian English',
    greeting:
        'Hello farmer partner, register your harvest to explore your options.',
  ),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    return StackItems(
      gap: 26,
      children: [
        Panel(
          color: Palette.pale,
          padding: 24,
          child: StackItems(
            gap: 12,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Tag(
                  'Step 1 of 2 · Voice setup',
                  color: Palette.surface,
                  icon: Icons.eco_outlined,
                ),
              ),
              Text(
                'Welcome to Harvest Twin',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const Text(
                'మీ పంటకు సరైన నిర్ణయం',
                style: TextStyle(
                  color: Palette.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const Text(
                'Clearer choices for your harvest. Explore where to sell, when to move, and what it could mean for you.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const Notice(
                'Offline demo ready\nExplore the complete flow with local example data.',
                icon: Icons.offline_bolt,
                color: Palette.surface,
              ),
            ],
          ),
        ),
        _ActiveCasesPanel(),
        ResponsiveColumns(
          main: StackItems(
            children: [
              const Heading(
                'Select language',
                trailing: Tag('6 languages', color: Palette.surface),
              ),
              const Text(
                'Choose your preferred language. Full translation and audio will be connected later.',
              ),
              for (final language in _languages)
                _LanguageCard(
                  native: language.native,
                  region: language.region,
                  greeting: language.greeting,
                  selected: prefs.language == language.name,
                  onTap: () => ref
                      .read(preferencesProvider.notifier)
                      .language(language.name),
                ),
            ],
          ),
          side: StackItems(
            children: [
              const Heading('Voice assistance mode'),
              const Text(
                'Designed for life in the field',
                style: TextStyle(
                  color: Palette.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _ModeCard(
                title: 'Full voice companion',
                subtitle: 'Hands-free guidance',
                icon: Icons.record_voice_over_outlined,
                detail:
                    'A preview of spoken guidance in your preferred language. Voice capture and playback are simulated in this demo.',
                selected: prefs.voice,
                onTap: () => ref.read(preferencesProvider.notifier).voice(true),
              ),
              _ModeCard(
                title: 'Standard visual mode',
                subtitle: 'Read and enter your details',
                icon: Icons.touch_app_outlined,
                detail:
                    'Clear visual cards and manual entry. Best if you prefer reading and typing at your own pace.',
                selected: !prefs.voice,
                onTap: () =>
                    ref.read(preferencesProvider.notifier).voice(false),
              ),
              const Notice(
                'Natural farmer tone\nA calm, simple preview for everyday decisions.',
                icon: Icons.graphic_eq,
                color: Palette.surface,
              ),
              PrimaryButton(
                'Continue to register harvest',
                onPressed: () => context.go('/register'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveCasesPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCases = ref.watch(activeCasesProvider);

    return Panel(
      child: StackItems(
        gap: 12,
        children: [
          const Heading('Your Active Cases', icon: Icons.inventory_2_outlined),
          asyncCases.when(
            data: (cases) {
              if (cases.isEmpty) {
                return const Notice(
                  'No active cases yet. Register a new harvest below.',
                  icon: Icons.info_outline,
                );
              }
              return Column(
                children: cases.map((c) => Panel(
                  color: Palette.surface,
                  padding: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.inventory, color: Palette.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Case #${c.id} · ${c.crop.name}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text('${c.quantityKg.toStringAsFixed(0)} kg · ${c.location}'),
                          ],
                        ),
                      ),
                      Tag(c.status, color: Palette.pale),
                    ],
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error loading cases: $e'),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.native,
    required this.region,
    required this.greeting,
    required this.selected,
    required this.onTap,
  });
  final String native, region, greeting;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? const Color(0xFF1C5041) : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: StackItems(
            gap: 14,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? Palette.mint : const Color(0xFFD6DDDA),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          native,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : Palette.ink,
                          ),
                        ),
                        Text(
                          region,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? Palette.mint : Palette.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Tag('Selected')
                  else
                    const Text(
                      'Tap to set',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 5, 5, 5),
                decoration: BoxDecoration(
                  color: selected ? Palette.green : Palette.surface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '“$greeting”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: selected ? Colors.white : Palette.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: selected
                            ? Colors.white
                            : const Color(0xFFE5E9E6),
                      ),
                      onPressed: () => showInfo(
                        context,
                        '$native voice preview',
                        '$greeting\n\nText preview only. Audio playback will be available when voice services are connected.',
                      ),
                      icon: const Icon(Icons.volume_up_outlined, size: 18),
                      label: const Text('Preview'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle, detail;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StackItems(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: selected
                        ? Palette.orange
                        : Palette.surface,
                    child: Icon(icon, color: Palette.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Palette.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? Palette.green : Colors.grey.shade300,
                  ),
                ],
              ),
              Text(detail),
              if (selected)
                const Notice(
                  'Selected for this session',
                  icon: Icons.hearing_outlined,
                  color: Palette.surface,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
