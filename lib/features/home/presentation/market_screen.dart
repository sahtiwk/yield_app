import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/supabase/supabase_client.dart';
import 'hyderabad_prices.dart';

final marketPricesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return [];
  return client
      .from('market_price_observations')
      .select('*,crop_configs(name),destinations(name)')
      .gte(
        'observed_for',
        DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 48))
            .toIso8601String(),
      )
      .lte('observed_for', DateTime.now().toUtc().toIso8601String())
      .neq('source_type', 'seed')
      .order('observed_for', ascending: false)
      .limit(100)
      .timeout(const Duration(seconds: 15));
});

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key, this.compact = false});
  final bool compact;
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
                t('Market Prices'),
                style: compact
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: t('Try again'),
              onPressed: () => ref.invalidate(marketPricesProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ref
            .watch(marketPricesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(marketPricesProvider),
                child: Text(t('Try again')),
              ),
              data: (rows) => rows.isEmpty
                  ? Text(t('No prices available'))
                  : Column(
                      children: [
                        for (final row in rows.take(compact ? 5 : 100))
                          ListTile(
                            title: Text(
                              '${t.externalLabel(row['crop_configs']['name'] as String, 'Crop')} · ${t.externalLabel(row['destinations']['name'] as String, 'market_destination')}',
                            ),
                            subtitle: Text(
                              '${t('reported_price')} · ${t.date(DateTime.parse(row['observed_for'] as String))}',
                            ),
                            trailing: Text(
                              t.format('price_unit', {
                                'value': t.money(row['price_per_kg'] as num),
                              }),
                            ),
                          ),
                      ],
                    ),
            ),
        if (!compact) ...[const Divider(height: 32), const HyderabadPrices()],
      ],
    );
  }
}
