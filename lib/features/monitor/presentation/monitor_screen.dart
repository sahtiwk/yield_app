import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/session_view.dart';
import '../../harvest_case/presentation/controllers/harvest_controller.dart';
import '../../recommendation/presentation/recommendation_screen.dart';

class MonitorScreen extends ConsumerWidget {
  const MonitorScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SessionView(
    builder: (session) {
      final r = session.recommendation;
      final c = session.harvestCase;
      return StackItems(
        gap: 22,
        children: [
          Panel(
            color: const Color(0xFFE6EBE7),
            child: StackItems(
              gap: 10,
              children: [
                Heading(
                  'Case #${c.id}',
                  icon: Icons.inventory_2_outlined,
                  trailing: const Tag('Demo active'),
                ),
                Text(
                  '${c.quantityKg.toStringAsFixed(0)} kg ${c.crop.name} · ${c.location}',
                ),
                const Text(
                  'Example monitoring window · until 6:00 PM',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ResponsiveColumns(
            main: StackItems(
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16003F32),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: session.changed ? Palette.orange : Palette.mint,
                        padding: const EdgeInsets.all(17),
                        child: Row(
                          children: [
                            Icon(
                              session.changed
                                  ? Icons.bolt
                                  : Icons.verified_outlined,
                              color: Palette.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                session.changed
                                    ? 'DEMO ALERT · HEAT SPIKE'
                                    : 'YOUR CURRENT PLAN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .7,
                                  color: Palette.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: StackItems(
                          gap: 18,
                          children: [
                            Text(
                              session.changed
                                  ? 'Recommendation changed!'
                                  : 'Your harvest is ready to follow',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            if (session.changed)
                              const Notice(
                                'In this example, transit temperature rises by 5°C. A shorter journey may help preserve crop quality.',
                                color: Palette.surface,
                                icon: Icons.device_thermostat,
                              )
                            else
                              const Text(
                                'You can explore how a change in conditions could affect the recommendation. Start the local simulation below.',
                              ),
                            Panel(
                              color: Palette.surface,
                              child: StackItems(
                                gap: 12,
                                children: [
                                  Text(
                                    session.changed
                                        ? 'SUGGESTED ROUTE CHANGE'
                                        : 'SUGGESTED DESTINATION',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: .6,
                                    ),
                                  ),
                                  Heading(
                                    r.destination.name.toUpperCase(),
                                    icon: Icons.alt_route,
                                  ),
                                  Text(
                                    '${r.destination.distanceKm.toStringAsFixed(0)} km away · ${r.destination.travelTime} estimated travel',
                                  ),
                                  if (session.changed)
                                    const Text(
                                      'Replaces the Growers market example (29 km).',
                                    ),
                                  Panel(
                                    padding: 14,
                                    child: StackItems(
                                      gap: 6,
                                      children: [
                                        const Text(
                                          'Example estimated net return',
                                        ),
                                        Text(
                                          r.expectedNetValue,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineLarge,
                                        ),
                                        Text(
                                          '${r.valueDifference} vs example baseline',
                                          style: const TextStyle(
                                            color: Palette.green,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (session.decision != null)
                              Notice(
                                session.decision!,
                                icon: Icons.check_circle_outline,
                              ),
                            if (session.changed &&
                                session.decision == null) ...[
                              PrimaryButton(
                                'Accept route change',
                                icon: Icons.near_me_outlined,
                                onPressed: () => ref
                                    .read(sessionProvider.notifier)
                                    .decide(
                                      'Route change accepted for this demo. No booking has been made.',
                                    ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final keep = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'Keep your original plan?',
                                      ),
                                      content: const Text(
                                        'The example heat alert suggests a shorter trip. You can still keep Growers market as your chosen destination.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Review change'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Keep original'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (keep == true && context.mounted) {
                                    ref
                                        .read(sessionProvider.notifier)
                                        .decide(
                                          'You chose to keep Growers market. The shorter-route suggestion remains available above.',
                                        );
                                  }
                                },
                                icon: const Icon(Icons.lock_outline),
                                label: const Text('Keep original plan'),
                              ),
                            ] else
                              PrimaryButton(
                                'View destination details',
                                icon: Icons.near_me_outlined,
                                onPressed: () => showDestination(context, r),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Panel(
                  color: const Color(0xFFE4E9E5),
                  child: StackItems(
                    children: [
                      const Heading(
                        'Demo scenario control',
                        icon: Icons.science_outlined,
                      ),
                      const Text(
                        'Load a second synthetic snapshot to preview a heat alert and a new destination. No weather feed or recommendation engine runs.',
                      ),
                      PrimaryButton(
                        session.changed
                            ? 'Replay heat alert example'
                            : 'Simulate a 5°C heat spike',
                        icon: Icons.cyclone_outlined,
                        color: Palette.amber,
                        onPressed: () =>
                            ref.read(sessionProvider.notifier).simulate(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            side: StackItems(
              children: [
                const Heading(
                  'Crop context',
                  trailing: Tag('Demo data', color: Palette.surface),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _ContextMetric(
                        icon: Icons.device_thermostat,
                        value: r.temperature,
                        label: 'Humidity ${r.humidity} · ambient',
                        alert: session.changed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ContextMetric(
                        icon: Icons.hourglass_top,
                        value: r.remainingWindow,
                        label: 'Example quality window',
                      ),
                    ),
                  ],
                ),
                Panel(
                  child: StackItems(
                    gap: 12,
                    children: [
                      const Heading('Example market rates'),
                      const Text(
                        'Tomato · illustrative offers',
                        style: TextStyle(fontSize: 12),
                      ),
                      for (final rate in r.marketRates)
                        Panel(
                          color:
                              rate.name.startsWith(
                                session.changed ? 'Riverside' : 'Growers',
                              )
                              ? Palette.pale
                              : Palette.surface,
                          padding: 12,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              Text(
                                rate.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                rate.price,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Palette.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Notice(
                  '${r.destination.travelTime} example transit\nRoad conditions have not been checked.',
                  icon: Icons.traffic_outlined,
                  color: Palette.surface,
                ),
                Panel(
                  padding: 0,
                  color: const Color(0xFFE5EBE2),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Heading(
                          'Route preview',
                          icon: Icons.map_outlined,
                          trailing: Tag('Schematic', color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 190,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _RoutePainter(),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Stack(
                              children: [
                                const Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Tag(
                                    'Your harvest',
                                    color: Colors.white,
                                    icon: Icons.agriculture,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Tag(
                                    r.destination.name,
                                    color: Colors.white,
                                    icon: Icons.storefront,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Illustration only · not a navigable map',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _ContextMetric extends StatelessWidget {
  const _ContextMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.alert = false,
  });
  final IconData icon;
  final String value, label;
  final bool alert;
  @override
  Widget build(BuildContext context) => Panel(
    color: Palette.surface,
    padding: 18,
    child: StackItems(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(icon, color: alert ? Palette.amber : Palette.green),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Palette.green),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x + 55, size.height), road);
    }
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 22), road);
    }
    final river = Paint()
      ..color = const Color(0xFFA8D5D3)
      ..strokeWidth = 17
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .68, 0)
        ..cubicTo(
          size.width * .3,
          60,
          size.width * .9,
          100,
          size.width * .55,
          size.height,
        ),
      river,
    );
    final path = Path()
      ..moveTo(48, size.height - 42)
      ..lineTo(size.width * .4, size.height - 60)
      ..lineTo(size.width * .47, 64)
      ..lineTo(size.width - 55, 42);
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.green
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(48, size.height - 42),
      7,
      Paint()..color = Palette.orange,
    );
    canvas.drawCircle(
      Offset(size.width - 55, 42),
      7,
      Paint()..color = Palette.green,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
