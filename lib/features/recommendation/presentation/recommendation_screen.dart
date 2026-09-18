import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/session_view.dart';
import '../domain/recommendation_snapshot.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});
  @override
  Widget build(BuildContext context) => SessionView(
    builder: (session) {
      final r = session.recommendation;
      final c = session.harvestCase;
      return StackItems(
        gap: 22,
        children: [
          Panel(
            padding: 14,
            child: Row(
              children: [
                IconButton.filled(
                  tooltip: 'Open recommendation briefing',
                  onPressed: () => showInfo(
                    context,
                    'Your recommendation · text briefing',
                    '${r.action} at ${r.destination.name}. Example estimated net value: ${r.expectedNetValue}. ${r.valueDifference} above the example baseline.\n\n${r.reasons.map((e) => e.detail).join('\n\n')}\n\nAudio is a preview only; no playback service is connected.',
                  ),
                  icon: const Icon(Icons.play_arrow_outlined),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMMENDATION BRIEFING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Palette.amber,
                          letterSpacing: .8,
                        ),
                      ),
                      Text(
                        'A clear next step for your harvest',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Tap to read · audio preview',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.graphic_eq, color: Palette.green),
              ],
            ),
          ),
          ResponsiveColumns(
            main: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12003F32),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(height: 7, color: Palette.green),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: StackItems(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Tag(
                            'BEST OPTION · DEMO EXAMPLE',
                            color: Color(0xFFA9F49B),
                            icon: Icons.verified_outlined,
                          ),
                        ),
                        Text(
                          'CASE ${c.id} · ${c.quantityKg.toStringAsFixed(0)} KG',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          r.action.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        Text(
                          '${c.crop.variety} ${c.crop.name.toLowerCase()} · ${c.farmerCondition}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Panel(
                          color: Palette.surface,
                          padding: 14,
                          child: StackItems(
                            gap: 9,
                            children: [
                              Heading(
                                r.destination.name,
                                icon: Icons.storefront_outlined,
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${r.destination.distanceKm.toStringAsFixed(0)} km away · ${r.destination.travelTime}',
                                  ),
                                  Tag(
                                    'Closes ${r.destination.closesAt}',
                                    color: const Color(0xFFE1E6E2),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'ESTIMATED NET VALUE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: .7,
                          ),
                        ),
                        Text(
                          r.expectedNetValue,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(fontSize: 38),
                        ),
                        Text(
                          'Range: ${r.range}\nAfter example transport & handling costs',
                        ),
                        Panel(
                          color: Palette.peach,
                          padding: 15,
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Palette.orange,
                                child: Icon(
                                  Icons.trending_up,
                                  color: Palette.amber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${r.valueDifference} estimated advantage',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF513117),
                                      ),
                                    ),
                                    Text(
                                      'Over the example current plan (${r.baselineValue} net)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Palette.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Why this option?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Palette.ink,
                          ),
                        ),
                        Panel(
                          color: Palette.surface,
                          padding: 14,
                          child: StackItems(
                            gap: 14,
                            children: [
                              for (final reason in r.reasons)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xFF25783A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reason.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Palette.ink,
                                            ),
                                          ),
                                          Text(reason.detail),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Text(
                          r.dataFreshness,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Notice(
                          'Fixed demo for a 650 kg tomato batch. Editing crop facts does not recalculate prices or recommendations.',
                          icon: Icons.info_outline,
                        ),
                        PrimaryButton(
                          'View route & buyer details',
                          icon: Icons.near_me_outlined,
                          onPressed: () => showDestination(context, r),
                        ),
                        Material(
                          color: Colors.white,
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text(
                              'Estimate details & assumptions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            leading: const Icon(Icons.receipt_long_outlined),
                            children: [
                              for (final assumption in r.assumptions)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(assumption),
                                ),
                              const Text(
                                'Example baseline: Village mandi. These illustrative figures are not a personalised quote.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            side: StackItems(
              children: [
                const Heading('Other evaluated options', icon: Icons.alt_route),
                for (final alternative in r.alternatives)
                  Panel(
                    child: StackItems(
                      gap: 12,
                      children: [
                        Heading(alternative.action),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(alternative.destination),
                            Tag(
                              alternative.status,
                              color: alternative.status == 'Not advised'
                                  ? const Color(0xFFFFDDDA)
                                  : Palette.surface,
                              foreground: alternative.status == 'Not advised'
                                  ? const Color(0xFFB83932)
                                  : Palette.muted,
                            ),
                          ],
                        ),
                        Text(
                          alternative.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 23,
                            color: Palette.muted,
                          ),
                        ),
                        Notice(
                          alternative.reason,
                          color: Palette.surface,
                          icon: Icons.info_outline,
                        ),
                      ],
                    ),
                  ),
                Panel(
                  child: StackItems(
                    children: [
                      const Heading('Example market context'),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              'Ambient weather',
                              r.temperature,
                              'Humidity ${r.humidity}',
                              Icons.wb_sunny_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: _Metric(
                              'Market demand',
                              'Steady',
                              'Synthetic snapshot',
                              Icons.local_shipping_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PrimaryButton(
                  'Monitor this harvest',
                  icon: Icons.sensors,
                  onPressed: () => context.go('/monitor'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/register'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit harvest facts'),
                ),
                const Text(
                  'Your choice stays yours. Estimates are not guaranteed returns.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

void showDestination(
  BuildContext context,
  RecommendationSnapshot r,
) => showInfo(
  context,
  'Route & buyer details',
  '${r.destination.name}\nApproximately ${r.destination.distanceKm.toStringAsFixed(0)} km · ${r.destination.travelTime}\nExample closing time: ${r.destination.closesAt}\n\nDemo route only. Check travel time and market opening hours locally.\n\nBuyer contact is not available in this demo. No buyer, sale or transport has been booked.',
);

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.note, this.icon);
  final String label, value, note;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(
    color: Palette.surface,
    padding: 12,
    child: StackItems(
      gap: 8,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        Icon(icon, color: Palette.green),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(note, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}
