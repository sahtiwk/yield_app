import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../harvest_case/domain/harvest_case.dart';
import '../domain/recommendation_snapshot.dart';

class ReferencePricePanel extends StatelessWidget {
  const ReferencePricePanel({
    super.key,
    required this.harvest,
    required this.quote,
    required this.t,
  });
  final HarvestCase harvest;
  final RecommendationSnapshot quote;
  final AppStrings t;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        color: const Color(0xFFE3F3EF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('reference_price'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.format('price_unit', {
                'value': t.preciseMoney(quote.referenceUnitPrice!),
              }),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            Text(t('reference_gross')),
            const SizedBox(height: 4),
            Text(
              t.money(quote.best.netValue),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${t.number(harvest.quantityKg)} ${t('kilogram')} × ${t.preciseMoney(quote.referenceUnitPrice!)}',
            ),
            const SizedBox(height: 12),
            Text('${t('Bowenpally')} | ${t.day(quote.observedAt)}'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(t('reference_notice'), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 16),
      Text(
        t(
          harvest.harvestStatus != 'Harvested'
              ? 'plan_before_sale'
              : harvest.farmerCondition == 'Damaged'
              ? 'grade_before_sale'
              : 'compare_before_sale',
        ),
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(t('Sources')),
        children: [for (final source in quote.sources) SelectableText(source)],
      ),
    ],
  );
}
