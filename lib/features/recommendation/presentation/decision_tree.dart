import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../harvest_case/presentation/controllers/harvest_controller.dart';

class DecisionTree extends StatelessWidget {
  const DecisionTree({super.key, required this.session, required this.t});
  final CaseSession session;
  final AppStrings t;

  @override
  Widget build(BuildContext context) {
    final c = session.harvestCase;
    final r = session.recommendation;
    final ready =
        c.harvestStatus == 'Harvested' && c.farmerCondition == 'Ready';
    return ExpansionTile(
      key: ValueKey('tree-${c.id}'),
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: false,
      title: Text(
        t('decision_tree'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      children: [
        _TreeNode(
          icon: Icons.agriculture_outlined,
          title: t(c.crop.name),
          detail:
              '${t.format('weight_value', {'value': t.number(c.quantityKg)})} | ${t(c.urgency)}',
          color: const Color(0xFF176A56),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFB6C7BF), width: 2),
              ),
            ),
            child: Column(
              children: [
                _Branch(
                  child: _TreeNode(
                    icon: Icons.location_on_outlined,
                    title: t('location_check'),
                    detail: t(
                      c.latitude != null && c.longitude != null
                          ? 'location_ready'
                          : 'coordinates_required',
                    ),
                    color: const Color(0xFF386AA5),
                  ),
                ),
                _Branch(
                  child: _TreeNode(
                    icon: Icons.fact_check_outlined,
                    title: t('quality_check'),
                    detail:
                        '${t(c.farmerCondition)} | ${t(ready ? 'quality_supported' : 'quality_review')}',
                    color: const Color(0xFF946321),
                  ),
                ),
                if (r != null && r.isReference)
                  _Branch(
                    child: _TreeNode(
                      icon: Icons.price_check,
                      title: t('reference_price'),
                      detail:
                          '${t.preciseMoney(r.referenceUnitPrice!)} / ${t('kilogram')}\n${t('reference_gross')}: ${t.money(r.best.netValue)}\n${t('Bowenpally')} | ${t.day(r.observedAt)}',
                      color: const Color(0xFF176A56),
                    ),
                  )
                else if (r == null)
                  _Branch(
                    child: _TreeNode(
                      icon: session.refreshing
                          ? Icons.sync
                          : Icons.cloud_off_outlined,
                      title: t(
                        session.refreshing
                            ? 'Evaluating options'
                            : 'estimate_pending',
                      ),
                      detail: t(session.issue ?? 'data_needed'),
                      color: const Color(0xFF705E83),
                    ),
                  )
                else ...[
                  for (final entry in [r.best, ...r.alternatives].indexed)
                    _Branch(
                      child: _TreeNode(
                        icon: entry.$1 == 0
                            ? Icons.check_circle_outline
                            : Icons.alt_route,
                        title: t.format('rank_label', {
                          'rank': t.number(entry.$1 + 1),
                        }),
                        detail:
                            '${t(entry.$2.action)} | ${t.externalLabel(entry.$2.name, 'market_destination')}\n${t.money(entry.$2.netValue)}',
                        color: entry.$1 == 0
                            ? const Color(0xFF176A56)
                            : const Color(0xFF386AA5),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(t('next_crop'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(
          t(
            ['tomato', 'brinjal', 'potato'].contains(c.crop.id)
                ? 'rotation_pulses'
                : 'rotation_review',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t('rotation_caution'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(t('Sources')),
          children: const [
            SelectableText(
              'https://agritech.tnau.ac.in/agriculture/agri_cropselect.html',
            ),
          ],
        ),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 2,
          margin: const EdgeInsets.only(top: 26),
          color: const Color(0xFFB6C7BF),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class _TreeNode extends StatelessWidget {
  const _TreeNode({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });
  final IconData icon;
  final String title, detail;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .06),
      border: Border(left: BorderSide(color: color, width: 3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(detail),
            ],
          ),
        ),
      ],
    ),
  );
}
