import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final id = client?.auth.currentUser?.id;
  if (client == null || id == null) return null;
  return client
      .from('profiles')
      .select('display_name,farm_name,district,farm_area_hectares')
      .eq('id', id)
      .single();
});
