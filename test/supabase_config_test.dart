import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yield_app/core/supabase/supabase_config.dart';

void main() {
  String token(String role) =>
      'header.${base64Url.encode(utf8.encode(jsonEncode({'role': role})))}.signature';
  SupabaseConfig config(String key, {String url = 'http://127.0.0.1:54321'}) =>
      SupabaseConfig(url: url, publicKey: key, isConfigured: true);
  test('Only public client keys are accepted', () {
    expect(() => config('sb_publishable_example').validate(), returnsNormally);
    expect(() => config(token('anon')).validate(), returnsNormally);
    for (final key in [
      'sb_secret_example',
      token('service_role'),
      'malformed',
    ]) {
      expect(() => config(key).validate(), throwsFormatException);
    }
    expect(
      () => config('sb_publishable_example', url: 'not-a-url').validate(),
      throwsFormatException,
    );
  });
}
