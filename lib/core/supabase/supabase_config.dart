import 'dart:convert';

class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.publicKey,
    required this.isConfigured,
  });

  static const _localUrl = 'http://127.0.0.1:54321';
  static const _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _localUrl,
  );
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  factory SupabaseConfig.fromEnvironment() {
    final key = _publishableKey.isNotEmpty ? _publishableKey : _anonKey;
    return SupabaseConfig(
      url: _url,
      publicKey: key,
      isConfigured: key.isNotEmpty,
    );
  }

  final String url;
  final String publicKey;
  final bool isConfigured;

  void validate() {
    if (!isConfigured) return;
    final endpoint = Uri.tryParse(url);
    if (endpoint == null ||
        !['http', 'https'].contains(endpoint.scheme) ||
        endpoint.host.isEmpty) {
      throw const FormatException(
        'SUPABASE_URL must be an HTTP or HTTPS API URL.',
      );
    }
    if (publicKey.startsWith('sb_publishable_') && publicKey.length > 15) {
      return;
    }
    try {
      final parts = publicKey.split('.');
      if (parts.length == 3) {
        final claims = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        if (claims is Map && claims['role'] == 'anon') return;
      }
    } catch (_) {
      // Reject malformed and privileged keys without echoing credentials.
    }
    throw const FormatException(
      'Flutter requires a public publishable or anon key. Privileged keys are forbidden.',
    );
  }
}
