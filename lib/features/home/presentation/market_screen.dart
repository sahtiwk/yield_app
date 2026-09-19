import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/supabase/supabase_client.dart';

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
      .limit(100);
});

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});
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
                style: Theme.of(context).textTheme.headlineMedium,
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
                        for (final row in rows)
                          ListTile(
                            title: Text(
                              '${t(row['crop_configs']['name'] as String)} · ${row['destinations']['name']}',
                            ),
                            subtitle: Text(
                              '${row['source_name']} · ${t.date(DateTime.parse(row['observed_for'] as String))}',
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
      ],
    );
  }
}
