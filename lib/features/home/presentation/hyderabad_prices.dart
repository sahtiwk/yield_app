import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/models/market_reference.dart';

class HyderabadPrices extends ConsumerWidget {
  const HyderabadPrices({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('hyderabad_prices'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('${t('Bowenpally')} | ${t.day(DateTime(2026, 9, 14))}'),
        const SizedBox(height: 8),
        Text(
          t('published_prices_notice'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final price in hyderabadReferencePrices.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.eco_outlined, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(t(price.key))),
                Text(
                  t.format('price_unit', {
                    'value': t.preciseMoney(price.value),
                  }),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(t('Sources')),
          children: [SelectableText(hyderabadPriceSource)],
        ),
      ],
    );
  }
}
