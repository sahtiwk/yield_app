import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

final supabaseConfigProvider = Provider<SupabaseConfig>(
  (ref) => SupabaseConfig.fromEnvironment(),
);

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(supabaseConfigProvider);
  if (!config.isConfigured) return null;
  return Supabase.instance.client;
});

final supabaseConnectionStatusProvider = FutureProvider<String>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final config = ref.watch(supabaseConfigProvider);

  if (client == null) {
    return 'Supabase not configured. Pass SUPABASE_PUBLISHABLE_KEY or SUPABASE_ANON_KEY with --dart-define.';
  }

  await client.from('crop_configs').select('id').limit(1);
  return 'Connected to ${config.url} with a public client key.';
});

Future<void> initializeSupabase(SupabaseConfig config) async {
  if (!config.isConfigured) return;
  config.validate();

  await Supabase.initialize(url: config.url, publishableKey: config.publicKey);
}
